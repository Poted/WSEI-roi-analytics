{{ config(materialized='table') }}

-- Position-based (U-shape) attribution:
--   1 touch  → 100% to that touch
--   2 touches → 50% first, 50% last
--   3+ touches → 40% first, 40% last, 20% split equally among middle touches

with converting_touchpoints as (
    select
        user_id,
        campaign_id,
        click_position,
        total_clicks_in_journey,
        click_cost
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
      and total_clicks_in_journey > 0
),

weighted as (
    select
        user_id,
        campaign_id,
        click_cost,
        case
            when total_clicks_in_journey = 1
                then 1.0
            when total_clicks_in_journey = 2
                then 0.5
            when click_position = 1
                then 0.4
            when click_position = total_clicks_in_journey
                then 0.4
            else 0.2 / nullif(total_clicks_in_journey - 2, 0)
        end                             as attribution_credit
    from converting_touchpoints
)

select
    campaign_id,
    'position_based'                            as attribution_model,
    round(sum(attribution_credit), 2)           as attributed_conversions,
    sum(click_cost)                             as total_spend,
    round(sum(click_cost)
        / nullif(sum(attribution_credit), 0), 2)
                                                as cpa
from weighted
group by campaign_id
