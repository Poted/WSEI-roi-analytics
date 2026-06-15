{{ config(materialized='table') }}

-- Cost-per-acquisition (CPA) by campaign from Criteo data.
-- Uses last-click attribution as the default model for spend attribution.

with touchpoints as (
    select
        campaign_id,
        user_id,
        click_cost,
        is_conversion_journey,
        click_position,
        total_clicks_in_journey
    from {{ ref('fact_touchpoints') }}
),

campaign_stats as (
    select
        campaign_id,

        count(*)                                                as total_impressions,
        count(distinct user_id)                                 as unique_users_reached,
        sum(click_cost)                                         as total_spend,

        count(distinct case when is_conversion_journey = 1 then user_id end)
                                                                as converting_users,

        -- Last-click conversions (touchpoint where position = total clicks)
        count(distinct case
            when is_conversion_journey = 1
             and click_position = total_clicks_in_journey
            then user_id
        end)                                                    as last_click_conversions,

        -- First-click conversions
        count(distinct case
            when is_conversion_journey = 1
             and click_position = 1
            then user_id
        end)                                                    as first_click_conversions,

        avg(case when is_conversion_journey = 1 then click_cost end)
                                                                as avg_cpc_converting

    from touchpoints
    group by campaign_id
)

select
    campaign_id,
    total_impressions,
    unique_users_reached,
    converting_users,
    last_click_conversions,
    first_click_conversions,
    round(total_spend, 2)                                           as total_spend,

    round(total_spend
        / nullif(last_click_conversions, 0), 2)                    as cpa_last_click,

    round(total_spend
        / nullif(first_click_conversions, 0), 2)                   as cpa_first_click,

    round(100.0 * converting_users
        / nullif(unique_users_reached, 0), 4)                      as conversion_rate_pct,

    round(coalesce(avg_cpc_converting, 0), 4)                      as avg_cpc_converting
from campaign_stats
order by total_spend desc
