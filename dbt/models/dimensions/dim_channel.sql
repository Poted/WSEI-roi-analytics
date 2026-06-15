{{ config(materialized='table') }}

with olist_channels as (
    select distinct
        acquisition_channel                   as channel_key,
        acquisition_channel                   as channel_name
    from {{ ref('stg_olist__leads_qualified') }}
    where acquisition_channel is not null
),

enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(['channel_key']) }}  as channel_id,
        channel_key,
        channel_name,
        case
            when channel_key = 'organic_search'  then 'Organic Search'
            when channel_key = 'paid_search'     then 'Paid Search'
            when channel_key = 'social_media'    then 'Social Media'
            when channel_key = 'email'           then 'Email'
            when channel_key = 'referral'        then 'Referral'
            when channel_key = 'direct_traffic'  then 'Direct'
            when channel_key = 'unknown'         then 'Unknown'
            else initcap(replace(channel_key, '_', ' '))
        end                                                      as channel_label,
        case
            when channel_key in ('organic_search', 'referral', 'direct_traffic') then 'Owned / Earned'
            when channel_key in ('paid_search')                                   then 'Paid'
            when channel_key in ('social_media')                                  then 'Social'
            when channel_key in ('email')                                          then 'CRM'
            else 'Other'
        end                                                      as channel_type
    from olist_channels
)

select * from enriched
