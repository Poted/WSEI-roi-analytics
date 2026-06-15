{{ config(materialized='table') }}

with converting_journeys as (
    select
        user_id,
        min(clicked_at)             as first_touch_at,
        max(clicked_at)             as last_touch_at,
        max(converted_at)           as converted_at,
        max(converted_at)::date     as conversion_date,
        max(total_clicks_in_journey) as total_touches,
        sum(click_cost)             as total_journey_cost,
        max(cost_per_order)         as cost_per_order
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
    group by user_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id', 'converted_at']) }}
                                                as conversion_id,
        user_id,
        conversion_date                         as date_id,
        first_touch_at,
        last_touch_at,
        converted_at,
        total_touches,
        total_journey_cost,
        cost_per_order,
        coalesce(
            extract(epoch from (converted_at - first_touch_at)) / 86400.0,
            0
        )::numeric(10,2)                        as journey_days
    from converting_journeys
    where converted_at is not null
)

select * from final
