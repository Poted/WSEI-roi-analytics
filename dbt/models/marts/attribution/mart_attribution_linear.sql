{{ config(materialized='table') }}

-- Linear attribution: conversion credit distributed equally across all touchpoints.

with converting_touchpoints as (
    select
        user_id,
        campaign_id,
        click_cost,
        total_clicks_in_journey,
        1.0 / total_clicks_in_journey   as attribution_credit
    from {{ ref('fact_touchpoints') }}
    where is_conversion_journey = 1
      and total_clicks_in_journey > 0
)

select
    campaign_id,
    'linear'                                as attribution_model,
    round(sum(attribution_credit), 2)       as attributed_conversions,
    sum(click_cost)                         as total_spend,
    round(sum(click_cost)
        / nullif(sum(attribution_credit), 0), 2)
                                            as cpa
from converting_touchpoints
group by campaign_id
