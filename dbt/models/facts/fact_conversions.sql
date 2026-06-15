{{ config(materialized='table') }}

-- One row per converting user journey (is_conversion_journey = 1).
-- Timestamps are relative seconds (Criteo anonymised data), not calendar dates.
-- journey_span_seconds: duration of journey in relative seconds.

with converting_journeys as (
    select
        user_id,
        conversion_id,
        max(total_clicks_in_journey)            as total_touches,
        min(click_timestamp_rel)                as first_touch_rel,
        max(click_timestamp_rel)                as last_touch_rel,
        max(conversion_timestamp_rel)           as conversion_timestamp_rel,
        sum(click_cost)                         as total_journey_cost,
        max(cost_per_order)                     as cost_per_order
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
      and conversion_id is not null
    group by user_id, conversion_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id', 'conversion_id']) }}
                                                as conversion_key,
        user_id,
        conversion_id,
        total_touches,
        first_touch_rel,
        last_touch_rel,
        conversion_timestamp_rel,
        (last_touch_rel - first_touch_rel)      as journey_span_seconds,
        total_journey_cost,
        cost_per_order
    from converting_journeys
)

select * from final
