{{ config(materialized='table') }}

-- First-click attribution: 100% credit to the first touchpoint in the journey.

with converting_touchpoints as (
    select
        user_id,
        campaign_id,
        click_position,
        click_cost
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
),

first_touches as (
    select
        user_id,
        campaign_id,
        click_cost,
        1.0                             as attribution_credit
    from converting_touchpoints
    where click_position = 1
)

select
    campaign_id,
    'first_click'                           as attribution_model,
    count(distinct user_id)                 as attributed_conversions,
    sum(click_cost)                         as total_spend,
    round(sum(click_cost)
        / nullif(count(distinct user_id), 0), 2)
                                            as cpa
from first_touches
group by campaign_id
