with source as (
    select * from {{ source('criteo', 'criteo_events') }}
),

renamed as (
    select
        uid::text                                                   as user_id,

        -- Criteo timestamps are relative seconds from dataset start (anonymised).
        -- They are NOT unix epoch; to_timestamp() will produce 1970-01-01 dates.
        -- Keep raw value for intra-journey ordering; real dates unavailable.
        timestamp::bigint                                           as click_timestamp_rel,

        campaign::text                                             as campaign_id,

        click::int                                                 as is_click,
        coalesce(conversion::int, 0)                               as is_conversion_journey,
        coalesce(attribution::int, 0)                              as criteo_attribution,

        -- -1 sentinel means "no conversion"; replace with NULL
        case when conversion_id::bigint = -1
            then null
            else conversion_id::text
        end                                                        as conversion_id,
        case when conversion_timestamp::bigint = -1
            then null
            else conversion_timestamp::bigint
        end                                                        as conversion_timestamp_rel,

        -- -1 sentinel means "impression, not a click"; replace with NULL
        nullif(click_pos::int, -1)                                 as click_position,
        nullif(click_nb::int, -1)                                  as total_clicks_in_journey,

        coalesce(cost::numeric, 0)                                 as click_cost,
        cpo::numeric                                               as cost_per_order,
        nullif(time_since_last_click::bigint, -1)                  as seconds_since_last_click,

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
