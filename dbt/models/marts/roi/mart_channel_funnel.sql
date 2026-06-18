{{ config(materialized='table') }}

-- Marketing funnel by acquisition channel (Olist).
-- Shows: leads → qualified → closed, conversion rates, avg deal value.

with leads as (
    select
        acquisition_channel,
        channel_id,
        count(*)                                                    as total_leads,
        sum(case when is_closed then 1 else 0 end)                  as closed_deals,
        avg(days_to_close)                                          as avg_days_to_close,
        avg(case when is_closed then declared_monthly_revenue_brl end)
                                                                    as avg_deal_revenue_brl,
        sum(case when is_closed then declared_monthly_revenue_brl else 0 end)
                                                                    as total_pipeline_brl
    from {{ ref('fact_leads') }}
    group by acquisition_channel, channel_id
),

enriched as (
    select
        l.acquisition_channel,
        l.channel_id,
        ch.channel_label,
        ch.channel_type,

        l.total_leads,
        l.closed_deals,
        l.total_leads - l.closed_deals                              as open_leads,

        round(100.0 * l.closed_deals
            / nullif(l.total_leads, 0), 2)                         as conversion_rate_pct,

        round(coalesce(l.avg_days_to_close, 0), 1)                 as avg_days_to_close,
        round(coalesce(l.avg_deal_revenue_brl, 0), 2)              as avg_deal_revenue_brl,
        round(coalesce(l.total_pipeline_brl, 0), 2)                as total_pipeline_brl
    from leads l
    left join {{ ref('dim_channel') }} ch on l.channel_id = ch.channel_id
)

select * from enriched
order by total_leads desc
