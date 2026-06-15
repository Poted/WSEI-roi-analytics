{{ config(materialized='table') }}

with events as (
    select * from {{ ref('stg_criteo__events') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id', 'click_timestamp_unix', 'campaign_id']) }}
                                                as touchpoint_id,
        user_id,
        campaign_id,
        click_date                              as date_id,
        clicked_at,

        click_position,
        total_clicks_in_journey,

        click_cost,
        seconds_since_last_click,

        is_conversion_journey,
        converted_at,
        cost_per_order,

        category_1,
        category_2,
        category_3
    from events
)

select * from final
