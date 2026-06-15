with source as (
    select * from {{ source('criteo', 'criteo_events') }}
),

renamed as (
    select
        uid::text                                                   as user_id,
        timestamp::bigint                                          as click_timestamp_unix,
        to_timestamp(timestamp::bigint)                            as clicked_at,
        date_trunc('day', to_timestamp(timestamp::bigint))::date   as click_date,

        campaign::text                                             as campaign_id,

        coalesce(conversion::int, 0)                               as is_conversion_journey,
        case
            when conversion_timestamp is null or conversion_timestamp::text = ''
            then null
            else to_timestamp(conversion_timestamp::bigint)
        end                                                        as converted_at,
        conversion_id::text                                        as conversion_id,

        coalesce(click_pos::int, 1)                                as click_position,
        coalesce(click_nb::int, 1)                                 as total_clicks_in_journey,

        coalesce(cost::numeric, 0)                                 as click_cost,
        cpo::numeric                                               as cost_per_order,
        time_since_last_click::numeric                             as seconds_since_last_click,

        cat1::text  as category_1,
        cat2::text  as category_2,
        cat3::text  as category_3,
        cat4::text  as category_4,
        cat5::text  as category_5,
        cat6::text  as category_6,
        cat7::text  as category_7,
        cat8::text  as category_8,
        cat9::text  as category_9
    from source
    where uid is not null
      and timestamp is not null
)

select * from renamed
