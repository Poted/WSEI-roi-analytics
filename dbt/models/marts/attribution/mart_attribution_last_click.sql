{{ config(materialized='table') }}

-- Last-click attribution: 100% credit to the final touchpoint before conversion.

with converting_touchpoints as (
    select
        user_id,
        campaign_id,
        click_position,
        total_clicks_in_journey,
        click_cost
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
),

last_touches as (
    select
        user_id,
        campaign_id,
        click_cost,
        1.0                             as attribution_credit
    from converting_touchpoints
    where click_position = total_clicks_in_journey
)

select
    campaign_id,
    'last_click'                            as attribution_model,
    count(distinct user_id)                 as attributed_conversions,
    sum(click_cost)                         as total_spend,
    round(sum(click_cost)
        / nullif(count(distinct user_id), 0), 2)
                                            as cpa
from last_touches
group by campaign_id
