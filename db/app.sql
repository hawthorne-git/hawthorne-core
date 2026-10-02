--
-- PostgreSQL database dump
--

\restrict 1VaVdbgyNQz3ssnyGCdTWS66P5iZMbmoqkCvHfL8xp2ae0hdcgKfhi2bUaThCTz

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg12+1)
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: code_delivery_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.code_delivery_type AS ENUM (
    'EMAIL',
    'PHONE'
);


--
-- Name: gtin_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gtin_source AS ENUM (
    'SUPPLIER',
    'HAWTHORNE'
);


--
-- Name: payment_method_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_method_type AS ENUM (
    'CREDIT_CARD'
);


--
-- Name: payment_service; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_service AS ENUM (
    'STRIPE'
);


--
-- Name: product_attr_data_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.product_attr_data_type AS ENUM (
    'Text',
    'Boolean',
    'Integer',
    'Decimal',
    'Select',
    'Reference'
);


--
-- Name: sewing_pattern_difficulty; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sewing_pattern_difficulty AS ENUM (
    'BEGINNER',
    'INTERMEDIATE',
    'ADVANCED',
    'UNKNOWN'
);


--
-- Name: site_sharing_scope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.site_sharing_scope AS ENUM (
    'HAWTHORNE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: artists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.artists (
    artist_id bigint NOT NULL,
    handle text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    token text NOT NULL,
    studio boolean DEFAULT false NOT NULL,
    website_url text,
    blog_url text,
    instagram_url text,
    facebook_url text,
    pinterest_url text,
    youtube_url text,
    tiktok_url text,
    bio_description text,
    bio_image_id bigint,
    hero_image_id bigint,
    twitter_url text,
    v2_attrs jsonb
);


--
-- Name: artists_artist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.artists ALTER COLUMN artist_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.artists_artist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    collection_id bigint NOT NULL,
    handle text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    token text NOT NULL,
    v2_attrs jsonb,
    description text
);


--
-- Name: collections_collection_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.collections ALTER COLUMN collection_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.collections_collection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    country_id bigint NOT NULL,
    handle text NOT NULL,
    code_alpha2 character(2) NOT NULL,
    code_alpha3 character(3) NOT NULL,
    code_numeric character(3) NOT NULL,
    ship_to boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    collect_tax boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.countries ALTER COLUMN country_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.countries_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: image_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.image_presets (
    image_preset_id bigint NOT NULL,
    handle text NOT NULL,
    widths integer[] NOT NULL,
    sizes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: image_presets_image_preset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.image_presets ALTER COLUMN image_preset_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.image_presets_image_preset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: image_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.image_types (
    image_type_id bigint NOT NULL,
    handle text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    image_preset_id bigint NOT NULL,
    slug text
);


--
-- Name: image_types_image_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.image_types ALTER COLUMN image_type_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.image_types_image_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.images (
    image_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    image_type_id bigint NOT NULL,
    token text NOT NULL,
    file_key text,
    active_storage_blob_id bigint,
    content_type text,
    byte_size bigint,
    width bigint,
    height bigint,
    alt_text text,
    file_version bigint DEFAULT 1 NOT NULL,
    alt_text_ai_model_prompt_id bigint,
    update_alt_text_with_ai boolean DEFAULT true NOT NULL
);


--
-- Name: images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.images ALTER COLUMN image_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.images_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: page_block_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_block_types (
    page_block_type_id bigint NOT NULL,
    handle text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    content_attrs text[] NOT NULL,
    required_content_attrs text[] NOT NULL
);


--
-- Name: page_block_types_page_block_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.page_block_types ALTER COLUMN page_block_type_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.page_block_types_page_block_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: page_layouts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_layouts (
    page_layout_id bigint NOT NULL,
    site_id bigint NOT NULL,
    page_type_id bigint NOT NULL,
    page_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    published boolean NOT NULL
);


--
-- Name: page_layouts_page_layout_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.page_layouts ALTER COLUMN page_layout_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.page_layouts_page_layout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: page_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_sections (
    page_section_id bigint NOT NULL,
    page_layout_id bigint NOT NULL,
    page_block_type_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    content_attrs jsonb NOT NULL,
    ui_attrs jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: page_sections_page_section_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.page_sections ALTER COLUMN page_section_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.page_sections_page_section_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: page_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_types (
    page_type_id bigint NOT NULL,
    handle text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: page_types_page_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.page_types ALTER COLUMN page_type_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.page_types_page_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_attrs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_attrs (
    product_attr_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    handle text NOT NULL,
    key text NOT NULL,
    data_type public.product_attr_data_type NOT NULL
);


--
-- Name: product_attrs_product_attr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.product_attrs ALTER COLUMN product_attr_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.product_attrs_product_attr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_type_attr_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_type_attr_options (
    product_type_attr_option_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    product_type_attr_id bigint NOT NULL,
    handle text NOT NULL,
    order_nbr smallint DEFAULT 0 NOT NULL,
    value text NOT NULL
);


--
-- Name: product_type_attr_options_product_type_attr_option_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.product_type_attr_options ALTER COLUMN product_type_attr_option_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.product_type_attr_options_product_type_attr_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_type_attrs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_type_attrs (
    product_type_attr_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    product_type_id bigint NOT NULL,
    product_attr_id bigint NOT NULL,
    unit text,
    required boolean DEFAULT false NOT NULL,
    reference_table text
);


--
-- Name: product_type_attrs_product_type_attr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.product_type_attrs ALTER COLUMN product_type_attr_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.product_type_attrs_product_type_attr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_types (
    product_type_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    handle text NOT NULL
);


--
-- Name: product_types_product_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.product_types ALTER COLUMN product_type_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.product_types_product_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    product_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    supplier_id bigint NOT NULL,
    artist_id bigint,
    list_price numeric(8,2) NOT NULL,
    sale_price numeric(8,2) NOT NULL,
    supplier_sku text,
    inventory_on_hand numeric(9,3) DEFAULT 0.000 NOT NULL,
    inventory_reserved numeric(9,3) DEFAULT 0.000 NOT NULL,
    inventory_on_order numeric(9,3) DEFAULT 0.000 NOT NULL,
    inventory_confirmed numeric(9,3) DEFAULT 0.000 NOT NULL,
    token text NOT NULL,
    gtin text,
    gtin_source public.gtin_source,
    retired_by_supplier boolean DEFAULT false NOT NULL,
    retired_by_hawthorne boolean DEFAULT false NOT NULL,
    product_type_id bigint NOT NULL,
    msrp numeric(8,2),
    map_price numeric(8,2),
    member_price numeric(8,2),
    adhere_to_map_price boolean DEFAULT true NOT NULL,
    description text,
    pull_location_id bigint,
    pick_location_id bigint,
    pull_nbr text,
    pick_nbr text,
    CONSTRAINT pick_location_or_pull_location CHECK (((pull_location_id IS NULL) OR (pick_location_id IS NULL))),
    CONSTRAINT pick_nbr_required_with_pick_location CHECK (((pick_location_id IS NULL) OR (pick_nbr IS NOT NULL))),
    CONSTRAINT pull_nbr_required_with_pull_location CHECK (((pull_location_id IS NULL) OR (pull_nbr IS NOT NULL))),
    CONSTRAINT sale_price_not_above_list_price CHECK ((sale_price <= list_price))
);


--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.products ALTER COLUMN product_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.products_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    site_id bigint NOT NULL,
    handle text NOT NULL,
    header_version integer DEFAULT 0 NOT NULL,
    footer_version integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    hawthorne_site boolean DEFAULT false NOT NULL,
    announcement_attrs jsonb,
    deleted_at timestamp with time zone,
    abbreviation text NOT NULL,
    mailer_send_domain_id text,
    mailer_send_webhook_secret text
);


--
-- Name: sites_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.sites ALTER COLUMN site_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sites_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    supplier_id bigint NOT NULL,
    handle text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    cc_fee_rate numeric(4,3) DEFAULT 0.000 NOT NULL,
    order_note text,
    discount_rate numeric(4,3) DEFAULT 0.000 NOT NULL,
    freight_cost_per_lb numeric(4,2) DEFAULT 0.00 NOT NULL,
    discount_per_yard numeric(3,2) DEFAULT 0.00 NOT NULL,
    reorder_note text,
    tariff_rate numeric(4,3) DEFAULT 0.000 NOT NULL,
    token text NOT NULL,
    v2_attrs jsonb
);


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.suppliers ALTER COLUMN supplier_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.suppliers_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: us_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.us_states (
    us_state_id bigint NOT NULL,
    handle text NOT NULL,
    code_alpha2 character(2) NOT NULL,
    ship_to boolean DEFAULT true NOT NULL,
    collect_tax boolean DEFAULT false NOT NULL,
    contiguous boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: us_states_us_state_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.us_states ALTER COLUMN us_state_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.us_states_us_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_addresses (
    user_address_id bigint NOT NULL,
    user_id bigint NOT NULL,
    token text NOT NULL,
    name text NOT NULL,
    street_address text NOT NULL,
    street_address_extended text,
    city text NOT NULL,
    state_province text NOT NULL,
    postal_code text NOT NULL,
    country_code_alpha2 character(2) CONSTRAINT user_shipping_addresses_country_code_alpha2_not_null NOT NULL,
    phone_number text NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_checkout_selected_at timestamp with time zone,
    deleted_at timestamp with time zone,
    "default" boolean DEFAULT false NOT NULL
);


--
-- Name: user_addresses_user_address_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.user_addresses ALTER COLUMN user_address_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_addresses_user_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_payment_methods (
    user_payment_method_id bigint NOT NULL,
    user_id bigint NOT NULL,
    payment_method_type public.payment_method_type NOT NULL,
    stripe_payment_method_id text,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    "default" boolean DEFAULT false NOT NULL,
    token text NOT NULL,
    last_checkout_selected_at timestamp with time zone,
    fingerprint text,
    service public.payment_service NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_payment_methods_user_payment_method_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.user_payment_methods ALTER COLUMN user_payment_method_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_payment_methods_user_payment_method_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sites (
    user_site_id bigint NOT NULL,
    site_id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_created_on_site boolean DEFAULT false NOT NULL,
    first_signed_in_at timestamp with time zone,
    last_signed_in_at timestamp with time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    keep_signed_in boolean DEFAULT false NOT NULL,
    sign_in_code character varying(6),
    sign_in_code_created_at timestamp with time zone,
    sign_in_code_failed_attempts_count smallint,
    new_phone_number text,
    new_phone_number_code character varying(6),
    new_phone_number_code_created_at timestamp with time zone,
    new_phone_number_code_failed_attempts_count smallint,
    new_email text,
    new_email_code character varying(6),
    new_email_code_created_at timestamp with time zone,
    new_email_code_failed_attempts_count smallint,
    delete_account_code character varying(6),
    delete_account_code_created_at timestamp with time zone,
    delete_account_code_failed_attempts_count smallint
);


--
-- Name: user_sites_user_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.user_sites ALTER COLUMN user_site_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_sites_user_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id bigint NOT NULL,
    token text NOT NULL,
    email text NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    phone_number text,
    sign_in_code_default_delivery public.code_delivery_type DEFAULT 'EMAIL'::public.code_delivery_type CONSTRAINT users_pin_default_delivery_not_null NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    name text,
    site_sharing_scope public.site_sharing_scope NOT NULL,
    deleted_at timestamp with time zone,
    stripe_customer_id text
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users ALTER COLUMN user_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: artists artists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY (artist_id);


--
-- Name: artists artists_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_uk_handle UNIQUE (handle);


--
-- Name: artists artists_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_uk_token UNIQUE (token);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (collection_id);


--
-- Name: countries countries_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pk PRIMARY KEY (country_id);


--
-- Name: countries countries_uk_code_alpha2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_uk_code_alpha2 UNIQUE (code_alpha2);


--
-- Name: countries countries_uk_code_alpha3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_uk_code_alpha3 UNIQUE (code_alpha3);


--
-- Name: countries countries_uk_code_numeric; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_uk_code_numeric UNIQUE (code_numeric);


--
-- Name: countries countries_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_uk_handle UNIQUE (handle);


--
-- Name: image_presets image_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_presets
    ADD CONSTRAINT image_presets_pkey PRIMARY KEY (image_preset_id);


--
-- Name: image_presets image_presets_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_presets
    ADD CONSTRAINT image_presets_uk_handle UNIQUE (handle);


--
-- Name: image_types image_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_types
    ADD CONSTRAINT image_types_pkey PRIMARY KEY (image_type_id);


--
-- Name: image_types image_types_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_types
    ADD CONSTRAINT image_types_uk_handle UNIQUE (handle);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (image_id);


--
-- Name: images images_uk_file_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_uk_file_key UNIQUE (file_key);


--
-- Name: images images_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_uk_token UNIQUE (token);


--
-- Name: page_block_types page_block_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_block_types
    ADD CONSTRAINT page_block_types_pkey PRIMARY KEY (page_block_type_id);


--
-- Name: page_block_types page_block_types_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_block_types
    ADD CONSTRAINT page_block_types_uk_handle UNIQUE (handle);


--
-- Name: page_layouts page_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_layouts
    ADD CONSTRAINT page_layouts_pkey PRIMARY KEY (page_layout_id);


--
-- Name: page_layouts page_layouts_uk_site_id_page_type_id_page_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_layouts
    ADD CONSTRAINT page_layouts_uk_site_id_page_type_id_page_id UNIQUE (site_id, page_type_id, page_id);


--
-- Name: page_sections page_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_sections
    ADD CONSTRAINT page_sections_pkey PRIMARY KEY (page_section_id);


--
-- Name: page_types page_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_types
    ADD CONSTRAINT page_types_pkey PRIMARY KEY (page_type_id);


--
-- Name: page_types page_types_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_types
    ADD CONSTRAINT page_types_uk_handle UNIQUE (handle);


--
-- Name: product_attrs product_attrs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_attrs
    ADD CONSTRAINT product_attrs_pkey PRIMARY KEY (product_attr_id);


--
-- Name: product_attrs product_attrs_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_attrs
    ADD CONSTRAINT product_attrs_uk_handle UNIQUE (handle);


--
-- Name: product_attrs product_attrs_uk_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_attrs
    ADD CONSTRAINT product_attrs_uk_key UNIQUE (key);


--
-- Name: product_type_attr_options product_type_attr_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attr_options
    ADD CONSTRAINT product_type_attr_options_pkey PRIMARY KEY (product_type_attr_option_id);


--
-- Name: product_type_attr_options product_type_attr_options_uk_product_type_attr_id_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attr_options
    ADD CONSTRAINT product_type_attr_options_uk_product_type_attr_id_handle UNIQUE (product_type_attr_id, handle);


--
-- Name: product_type_attr_options product_type_attr_options_uk_product_type_attr_id_value; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attr_options
    ADD CONSTRAINT product_type_attr_options_uk_product_type_attr_id_value UNIQUE (product_type_attr_id, value);


--
-- Name: product_type_attrs product_type_attrs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attrs
    ADD CONSTRAINT product_type_attrs_pkey PRIMARY KEY (product_type_attr_id);


--
-- Name: product_type_attrs product_type_attrs_uk_product_type_id_product_attr_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attrs
    ADD CONSTRAINT product_type_attrs_uk_product_type_id_product_attr_id UNIQUE (product_type_id, product_attr_id);


--
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (product_type_id);


--
-- Name: product_types product_types_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_uk_handle UNIQUE (handle);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: products products_uk_gtin; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_uk_gtin UNIQUE (gtin);


--
-- Name: products products_uk_supplier_id_supplier_sku; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_uk_supplier_id_supplier_sku UNIQUE (supplier_id, supplier_sku);


--
-- Name: products products_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_uk_token UNIQUE (token);


--
-- Name: sites sites_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pk PRIMARY KEY (site_id);


--
-- Name: sites sites_uk_abbreviation; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_uk_abbreviation UNIQUE (abbreviation);


--
-- Name: sites sites_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_uk_handle UNIQUE (handle);


--
-- Name: sites sites_uk_mailer_send_domain_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_uk_mailer_send_domain_id UNIQUE (mailer_send_domain_id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- Name: suppliers suppliers_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_uk_handle UNIQUE (handle);


--
-- Name: suppliers suppliers_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_uk_token UNIQUE (token);


--
-- Name: us_states us_states_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.us_states
    ADD CONSTRAINT us_states_pk PRIMARY KEY (us_state_id);


--
-- Name: us_states us_states_uk_code_alpha2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.us_states
    ADD CONSTRAINT us_states_uk_code_alpha2 UNIQUE (code_alpha2);


--
-- Name: us_states us_states_uk_handle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.us_states
    ADD CONSTRAINT us_states_uk_handle UNIQUE (handle);


--
-- Name: user_addresses user_addresses_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_pk PRIMARY KEY (user_address_id);


--
-- Name: user_addresses user_addresses_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_uk_token UNIQUE (token);


--
-- Name: user_payment_methods user_payment_methods_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_payment_methods
    ADD CONSTRAINT user_payment_methods_pk PRIMARY KEY (user_payment_method_id);


--
-- Name: user_payment_methods user_payment_methods_uk_stripe_payment_method_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_payment_methods
    ADD CONSTRAINT user_payment_methods_uk_stripe_payment_method_id UNIQUE (stripe_payment_method_id);


--
-- Name: user_payment_methods user_payment_methods_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_payment_methods
    ADD CONSTRAINT user_payment_methods_uk_token UNIQUE (token);


--
-- Name: user_payment_methods user_payment_methods_uk_user_id_fingerprint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_payment_methods
    ADD CONSTRAINT user_payment_methods_uk_user_id_fingerprint UNIQUE (user_id, fingerprint);


--
-- Name: user_sites user_sites_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sites
    ADD CONSTRAINT user_sites_pk PRIMARY KEY (user_site_id);


--
-- Name: user_sites user_sites_uk_site_id_user_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sites
    ADD CONSTRAINT user_sites_uk_site_id_user_id UNIQUE (site_id, user_id);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (user_id);


--
-- Name: users users_uk_email_site_sharing_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_uk_email_site_sharing_scope UNIQUE (email, site_sharing_scope);


--
-- Name: users users_uk_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_uk_token UNIQUE (token);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: page_sections_idx_page_layout_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_sections_idx_page_layout_id ON public.page_sections USING btree (page_layout_id);


--
-- Name: user_addresses_idx_city_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_city_trgm ON public.user_addresses USING gin (city public.gin_trgm_ops);


--
-- Name: user_addresses_idx_country_code_alpha2_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_country_code_alpha2_created_at ON public.user_addresses USING btree (country_code_alpha2, created_at);


--
-- Name: user_addresses_idx_country_code_alpha2_state_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_country_code_alpha2_state_province ON public.user_addresses USING btree (country_code_alpha2, state_province);


--
-- Name: user_addresses_idx_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_created_at ON public.user_addresses USING btree (created_at);


--
-- Name: user_addresses_idx_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_name_trgm ON public.user_addresses USING gin (name public.gin_trgm_ops);


--
-- Name: user_addresses_idx_state_province_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_state_province_trgm ON public.user_addresses USING gin (state_province public.gin_trgm_ops);


--
-- Name: user_addresses_idx_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_addresses_idx_user_id ON public.user_addresses USING btree (user_id);


--
-- Name: user_addresses_uk_user_id_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_addresses_uk_user_id_default ON public.user_addresses USING btree (user_id) WHERE ("default" AND (NOT deleted));


--
-- Name: user_payment_methods_idx_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_payment_methods_idx_created_at ON public.user_payment_methods USING btree (created_at);


--
-- Name: user_payment_methods_idx_fingerprint_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_payment_methods_idx_fingerprint_trgm ON public.user_payment_methods USING gin (fingerprint public.gin_trgm_ops);


--
-- Name: user_payment_methods_idx_stripe_payment_method_id_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_payment_methods_idx_stripe_payment_method_id_trgm ON public.user_payment_methods USING gin (stripe_payment_method_id public.gin_trgm_ops);


--
-- Name: user_payment_methods_idx_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_payment_methods_idx_user_id ON public.user_payment_methods USING btree (user_id);


--
-- Name: user_payment_methods_uk_user_id_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_payment_methods_uk_user_id_default ON public.user_payment_methods USING btree (user_id) WHERE ("default" AND (NOT deleted));


--
-- Name: user_sites_idx_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_sites_idx_user_id ON public.user_sites USING btree (user_id);


--
-- Name: users_idx_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_idx_created_at ON public.users USING btree (created_at);


--
-- Name: users_idx_email_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_idx_email_trgm ON public.users USING gin (email public.gin_trgm_ops);


--
-- Name: users_idx_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_idx_name_trgm ON public.users USING gin (name public.gin_trgm_ops);


--
-- Name: users_idx_phone_number_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_idx_phone_number_trgm ON public.users USING gin (phone_number public.gin_trgm_ops);


--
-- Name: artists artists_bio_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_bio_image_id_fkey FOREIGN KEY (bio_image_id) REFERENCES public.images(image_id);


--
-- Name: active_storage_attachments fk_active_storage_attachments_blob; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_active_storage_attachments_blob FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: active_storage_variant_records fk_active_storage_variant_records_blob; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_active_storage_variant_records_blob FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: image_types image_types_image_presets_image_preset_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_types
    ADD CONSTRAINT image_types_image_presets_image_preset_id_fk FOREIGN KEY (image_preset_id) REFERENCES public.image_presets(image_preset_id);


--
-- Name: images images_image_types_image_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_image_types_image_type_id_fk FOREIGN KEY (image_type_id) REFERENCES public.image_types(image_type_id);


--
-- Name: page_layouts page_layouts_page_types_page_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_layouts
    ADD CONSTRAINT page_layouts_page_types_page_type_id_fk FOREIGN KEY (page_type_id) REFERENCES public.page_types(page_type_id);


--
-- Name: page_layouts page_layouts_sites_site_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_layouts
    ADD CONSTRAINT page_layouts_sites_site_id_fk FOREIGN KEY (site_id) REFERENCES public.sites(site_id);


--
-- Name: page_sections page_sections_page_block_types_page_block_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_sections
    ADD CONSTRAINT page_sections_page_block_types_page_block_type_id_fk FOREIGN KEY (page_block_type_id) REFERENCES public.page_block_types(page_block_type_id);


--
-- Name: page_sections page_sections_page_layouts_page_layout_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_sections
    ADD CONSTRAINT page_sections_page_layouts_page_layout_id_fk FOREIGN KEY (page_layout_id) REFERENCES public.page_layouts(page_layout_id);


--
-- Name: product_type_attr_options product_type_attr_options_product_type_attrs_product_type_attr_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attr_options
    ADD CONSTRAINT product_type_attr_options_product_type_attrs_product_type_attr_ FOREIGN KEY (product_type_attr_id) REFERENCES public.product_type_attrs(product_type_attr_id);


--
-- Name: product_type_attrs product_type_attrs_product_attrs_product_attr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attrs
    ADD CONSTRAINT product_type_attrs_product_attrs_product_attr_id_fk FOREIGN KEY (product_attr_id) REFERENCES public.product_attrs(product_attr_id);


--
-- Name: product_type_attrs product_type_attrs_product_types_product_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type_attrs
    ADD CONSTRAINT product_type_attrs_product_types_product_type_id_fk FOREIGN KEY (product_type_id) REFERENCES public.product_types(product_type_id);


--
-- Name: products products_artists_artist_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_artists_artist_id_fk FOREIGN KEY (artist_id) REFERENCES public.artists(artist_id);


--
-- Name: products products_suppliers_supplier_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_suppliers_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id);


--
-- Name: user_addresses user_addresses_countries_code_alpha2_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_countries_code_alpha2_fk FOREIGN KEY (country_code_alpha2) REFERENCES public.countries(code_alpha2);


--
-- Name: user_addresses user_addresses_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_users_user_id_fk FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: user_payment_methods user_payment_methods_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_payment_methods
    ADD CONSTRAINT user_payment_methods_users_user_id_fk FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: user_sites user_sites_sites_site_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sites
    ADD CONSTRAINT user_sites_sites_site_id_fk FOREIGN KEY (site_id) REFERENCES public.sites(site_id);


--
-- Name: user_sites user_sites_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sites
    ADD CONSTRAINT user_sites_users_user_id_fk FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 1VaVdbgyNQz3ssnyGCdTWS66P5iZMbmoqkCvHfL8xp2ae0hdcgKfhi2bUaThCTz

