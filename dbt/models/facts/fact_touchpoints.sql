{{ config(materialized='table') }}

-- Only click events (is_click = 1); impressions (is_click = 0) have no journey
-- position data and are not useful for attribution models.
-- Note: click_timestamp_rel is relative seconds, not a calendar date.

with events as (
    select * from {{ ref('stg_criteo__events') }}
    where is_click = 1
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id', 'click_timestamp_rel', 'campaign_id']) }}
                                                as touchpoint_id,
        user_id,
        campaign_id,

        click_timestamp_rel,
        click_position,
        total_clicks_in_journey,

        click_cost,
        seconds_since_last_click,

        is_conversion_journey,
        conversion_id,
        conversion_timestamp_rel,
        cost_per_order,

        criteo_attribution,

        category_1,
        category_2,
        category_3,
        category_4,
        category_5,
        category_6,
        category_7,
        category_8,
        category_9

    from events
)

select * from final
