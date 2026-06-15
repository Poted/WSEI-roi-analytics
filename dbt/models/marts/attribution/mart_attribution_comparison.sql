{{ config(materialized='table') }}

-- Side-by-side comparison of all attribution models per campaign.
-- Use this table in Metabase to visualise how model choice shifts credit between campaigns.

with all_models as (
    select * from {{ ref('mart_attribution_last_click') }}
    union all
    select * from {{ ref('mart_attribution_first_click') }}
    union all
    select * from {{ ref('mart_attribution_linear') }}
    union all
    select * from {{ ref('mart_attribution_time_decay') }}
    union all
    select * from {{ ref('mart_attribution_position_based') }}
)

select
    campaign_id,
    attribution_model,
    attributed_conversions,
    total_spend,
    cpa
from all_models
order by campaign_id, attribution_model
