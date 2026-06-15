{{ config(materialized='table') }}

-- Time-decay attribution: more credit to touchpoints closer to the conversion.
-- Weight = 0.5 ^ ((total_clicks - click_position) / 7.0)  (half-life of 7 positions).
-- Weights are normalised within each user journey.

with converting_touchpoints as (
    select
        user_id,
        campaign_id,
        click_position,
        total_clicks_in_journey,
        click_cost,
        power(0.5, (total_clicks_in_journey - click_position)::float / 7.0)
                                        as raw_weight
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
      and total_clicks_in_journey > 0
),

with_journey_weight as (
    select
        user_id,
        campaign_id,
        click_cost,
        raw_weight,
        sum(raw_weight) over (partition by user_id) as journey_total_weight
    from converting_touchpoints
),

weighted as (
    select
        user_id,
        campaign_id,
        click_cost,
        raw_weight / nullif(journey_total_weight, 0)    as attribution_credit
    from with_journey_weight
)

select
    campaign_id,
    'time_decay'                                as attribution_model,
    round(sum(attribution_credit), 2)           as attributed_conversions,
    sum(click_cost)                             as total_spend,
    round(sum(click_cost)
        / nullif(sum(attribution_credit), 0), 2)
                                                as cpa
from weighted
group by campaign_id
