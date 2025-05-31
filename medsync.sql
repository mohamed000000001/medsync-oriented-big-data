--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

-- Started on 2025-05-19 12:26:12 +01

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

DROP DATABASE IF EXISTS medsync;
--
-- TOC entry 3804 (class 1262 OID 16694)
-- Name: medsync; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE medsync WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';


ALTER DATABASE medsync OWNER TO postgres;

\connect medsync

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
-- TOC entry 911 (class 1247 OID 16878)
-- Name: enum_Appointments_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Appointments_status" AS ENUM (
    'pending',
    'confirmed',
    'cancelled'
);


ALTER TYPE public."enum_Appointments_status" OWNER TO postgres;

--
-- TOC entry 905 (class 1247 OID 16846)
-- Name: enum_Users_bloodGroup; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Users_bloodGroup" AS ENUM (
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
);


ALTER TYPE public."enum_Users_bloodGroup" OWNER TO postgres;

--
-- TOC entry 902 (class 1247 OID 16839)
-- Name: enum_Users_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."enum_Users_role" AS ENUM (
    'admin',
    'doctor',
    'patient'
);


ALTER TYPE public."enum_Users_role" OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16779)
-- Name: get_available_slots(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_available_slots(p_doctor_id integer, p_date date) RETURNS TABLE(start_time timestamp with time zone, end_time timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_day_of_week INTEGER;
  v_availability RECORD;
  v_start_time TIME;
  v_end_time TIME;
  v_slot_duration INTEGER;
BEGIN
  v_day_of_week := EXTRACT(DOW FROM p_date);
  
  -- Get doctor's availability for the day
  SELECT * INTO v_availability
  FROM doctor_availability
  WHERE doctor_id = p_doctor_id
    AND day_of_week = v_day_of_week
    AND is_available = true;
    
  IF v_availability IS NULL THEN
    RETURN;
  END IF;
  
  v_start_time := v_availability.start_time;
  v_end_time := v_availability.end_time;
  v_slot_duration := v_availability.slot_duration;
  
  -- Generate available slots
  WHILE v_start_time + (v_slot_duration || ' minutes')::INTERVAL <= v_end_time LOOP
    -- Check if slot is already booked
    IF NOT EXISTS (
      SELECT 1
      FROM appointments
      WHERE doctor_id = p_doctor_id
        AND start_time = (p_date + v_start_time)
        AND status != 'cancelled'
    ) THEN
      start_time := p_date + v_start_time;
      end_time := p_date + (v_start_time + (v_slot_duration || ' minutes')::INTERVAL);
      RETURN NEXT;
    END IF;
    
    v_start_time := v_start_time + (v_slot_duration || ' minutes')::INTERVAL;
  END LOOP;
END;
$$;


ALTER FUNCTION public.get_available_slots(p_doctor_id integer, p_date date) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 16774)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 238 (class 1259 OID 16886)
-- Name: Appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Appointments" (
    id integer NOT NULL,
    "patientEmail" character varying(255) NOT NULL,
    "doctorEmail" character varying(255) NOT NULL,
    date date NOT NULL,
    "startTime" time without time zone NOT NULL,
    "endTime" time without time zone NOT NULL,
    status public."enum_Appointments_status" DEFAULT 'pending'::public."enum_Appointments_status",
    notes character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Appointments" OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16885)
-- Name: Appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Appointments_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Appointments_id_seq" OWNER TO postgres;

--
-- TOC entry 3805 (class 0 OID 0)
-- Dependencies: 237
-- Name: Appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Appointments_id_seq" OWNED BY public."Appointments".id;


--
-- TOC entry 244 (class 1259 OID 16925)
-- Name: Messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Messages" (
    id integer NOT NULL,
    "senderEmail" character varying(255) NOT NULL,
    "receiverEmail" character varying(255) NOT NULL,
    content character varying(255) NOT NULL,
    read boolean DEFAULT false,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Messages" OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16924)
-- Name: Messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Messages_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Messages_id_seq" OWNER TO postgres;

--
-- TOC entry 3806 (class 0 OID 0)
-- Dependencies: 243
-- Name: Messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Messages_id_seq" OWNED BY public."Messages".id;


--
-- TOC entry 242 (class 1259 OID 16915)
-- Name: Notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Notifications" (
    id integer NOT NULL,
    "senderEmail" character varying(255) NOT NULL,
    "receiverEmail" character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    message character varying(255) NOT NULL,
    read boolean DEFAULT false,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Notifications" OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16914)
-- Name: Notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Notifications_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Notifications_id_seq" OWNER TO postgres;

--
-- TOC entry 3807 (class 0 OID 0)
-- Dependencies: 241
-- Name: Notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Notifications_id_seq" OWNED BY public."Notifications".id;


--
-- TOC entry 240 (class 1259 OID 16901)
-- Name: Reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Reviews" (
    id integer NOT NULL,
    "doctorEmail" character varying(255) NOT NULL,
    "patientEmail" character varying(255) NOT NULL,
    rating integer NOT NULL,
    comment character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Reviews" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16900)
-- Name: Reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Reviews_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Reviews_id_seq" OWNER TO postgres;

--
-- TOC entry 3808 (class 0 OID 0)
-- Dependencies: 239
-- Name: Reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Reviews_id_seq" OWNED BY public."Reviews".id;


--
-- TOC entry 236 (class 1259 OID 16864)
-- Name: Users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Users" (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) DEFAULT 'medsync123'::character varying NOT NULL,
    role public."enum_Users_role" NOT NULL,
    "firstName" character varying(255) NOT NULL,
    "lastName" character varying(255) NOT NULL,
    "profilePicture" character varying(255) DEFAULT NULL::character varying,
    "phoneNumber" character varying(255),
    specialization character varying(255),
    qualifications json,
    experience integer,
    "consultationFee" integer,
    "dateOfBirth" timestamp with time zone,
    "bloodGroup" public."enum_Users_bloodGroup",
    "medicalHistory" json,
    address json,
    "isActive" boolean DEFAULT true,
    "lastLogin" timestamp with time zone,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."Users" OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16863)
-- Name: Users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Users_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Users_id_seq" OWNER TO postgres;

--
-- TOC entry 3809 (class 0 OID 0)
-- Dependencies: 235
-- Name: Users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Users_id_seq" OWNED BY public."Users".id;


--
-- TOC entry 222 (class 1259 OID 16727)
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id integer NOT NULL,
    patient_id integer,
    doctor_id integer,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    notes text,
    cancellation_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT appointments_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'cancelled'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16790)
-- Name: appointments_email; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments_email (
    id integer NOT NULL,
    patient_email character varying(255) NOT NULL,
    doctor_email character varying(255) NOT NULL,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT appointments_email_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.appointments_email OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16789)
-- Name: appointments_email_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_email_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_email_id_seq OWNER TO postgres;

--
-- TOC entry 3810 (class 0 OID 0)
-- Dependencies: 227
-- Name: appointments_email_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_email_id_seq OWNED BY public.appointments_email.id;


--
-- TOC entry 221 (class 1259 OID 16726)
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_id_seq OWNER TO postgres;

--
-- TOC entry 3811 (class 0 OID 0)
-- Dependencies: 221
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- TOC entry 224 (class 1259 OID 16750)
-- Name: doctor_availability; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctor_availability (
    id integer NOT NULL,
    doctor_id integer,
    day_of_week integer NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_available boolean DEFAULT true,
    slot_duration integer DEFAULT 30,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT doctor_availability_day_of_week_check CHECK (((day_of_week >= 0) AND (day_of_week <= 6))),
    CONSTRAINT doctor_availability_slot_duration_check CHECK (((slot_duration >= 15) AND (slot_duration <= 120)))
);


ALTER TABLE public.doctor_availability OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16749)
-- Name: doctor_availability_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctor_availability_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doctor_availability_id_seq OWNER TO postgres;

--
-- TOC entry 3812 (class 0 OID 0)
-- Dependencies: 223
-- Name: doctor_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctor_availability_id_seq OWNED BY public.doctor_availability.id;


--
-- TOC entry 226 (class 1259 OID 16781)
-- Name: doctors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctors (
    id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(20),
    specialty character varying(100),
    profile_picture character varying(255)
);


ALTER TABLE public.doctors OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16780)
-- Name: doctors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doctors_id_seq OWNER TO postgres;

--
-- TOC entry 3813 (class 0 OID 0)
-- Dependencies: 225
-- Name: doctors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctors_id_seq OWNED BY public.doctors.id;


--
-- TOC entry 234 (class 1259 OID 16827)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_email character varying(255) NOT NULL,
    receiver_email character varying(255) NOT NULL,
    content text NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16826)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- TOC entry 3814 (class 0 OID 0)
-- Dependencies: 233
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- TOC entry 232 (class 1259 OID 16815)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    sender_email character varying(255) NOT NULL,
    receiver_email character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    message text NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16814)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 3815 (class 0 OID 0)
-- Dependencies: 231
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 220 (class 1259 OID 16711)
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    user_id integer,
    full_name character varying(100) NOT NULL,
    phone character varying(20),
    specialty character varying(100),
    experience_years integer,
    bio text,
    address character varying(255),
    city character varying(100),
    profile_picture character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16710)
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profiles_id_seq OWNER TO postgres;

--
-- TOC entry 3816 (class 0 OID 0)
-- Dependencies: 219
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- TOC entry 230 (class 1259 OID 16803)
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    doctor_email character varying(255) NOT NULL,
    patient_email character varying(255) NOT NULL,
    rating integer NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16802)
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO postgres;

--
-- TOC entry 3817 (class 0 OID 0)
-- Dependencies: 229
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- TOC entry 218 (class 1259 OID 16696)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    full_name character varying(255),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['patient'::character varying, 'doctor'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16695)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3818 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 3562 (class 2604 OID 16889)
-- Name: Appointments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointments" ALTER COLUMN id SET DEFAULT nextval('public."Appointments_id_seq"'::regclass);


--
-- TOC entry 3567 (class 2604 OID 16928)
-- Name: Messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Messages" ALTER COLUMN id SET DEFAULT nextval('public."Messages_id_seq"'::regclass);


--
-- TOC entry 3565 (class 2604 OID 16918)
-- Name: Notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Notifications" ALTER COLUMN id SET DEFAULT nextval('public."Notifications_id_seq"'::regclass);


--
-- TOC entry 3564 (class 2604 OID 16904)
-- Name: Reviews id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews" ALTER COLUMN id SET DEFAULT nextval('public."Reviews_id_seq"'::regclass);


--
-- TOC entry 3558 (class 2604 OID 16867)
-- Name: Users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users" ALTER COLUMN id SET DEFAULT nextval('public."Users_id_seq"'::regclass);


--
-- TOC entry 3533 (class 2604 OID 16730)
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- TOC entry 3543 (class 2604 OID 16793)
-- Name: appointments_email id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments_email ALTER COLUMN id SET DEFAULT nextval('public.appointments_email_id_seq'::regclass);


--
-- TOC entry 3537 (class 2604 OID 16753)
-- Name: doctor_availability id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability ALTER COLUMN id SET DEFAULT nextval('public.doctor_availability_id_seq'::regclass);


--
-- TOC entry 3542 (class 2604 OID 16784)
-- Name: doctors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors ALTER COLUMN id SET DEFAULT nextval('public.doctors_id_seq'::regclass);


--
-- TOC entry 3554 (class 2604 OID 16830)
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- TOC entry 3550 (class 2604 OID 16818)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 3530 (class 2604 OID 16714)
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- TOC entry 3547 (class 2604 OID 16806)
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- TOC entry 3526 (class 2604 OID 16699)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3792 (class 0 OID 16886)
-- Dependencies: 238
-- Data for Name: Appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3798 (class 0 OID 16925)
-- Dependencies: 244
-- Data for Name: Messages; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3796 (class 0 OID 16915)
-- Dependencies: 242
-- Data for Name: Notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3794 (class 0 OID 16901)
-- Dependencies: 240
-- Data for Name: Reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3790 (class 0 OID 16864)
-- Dependencies: 236
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3776 (class 0 OID 16727)
-- Dependencies: 222
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3782 (class 0 OID 16790)
-- Dependencies: 228
-- Data for Name: appointments_email; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3778 (class 0 OID 16750)
-- Dependencies: 224
-- Data for Name: doctor_availability; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3780 (class 0 OID 16781)
-- Dependencies: 226
-- Data for Name: doctors; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (1, 'Ali Rayhi', 'ali.rayhi@medsync.com', '0612345678', 'Cardiology', 'docAliRayhi.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (2, 'Asmae Khamlichi', 'asmae.khamlichi@medsync.com', '0623456789', 'Dermatology', 'docAsmaekhamlichi.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (3, 'Houssam Moutarajji', 'houssam.moutarajji@medsync.com', '0634567890', 'Endocrinology', 'docHoussamMoutarajji.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (4, 'Khadija Arache', 'khadija.arache@medsync.com', '0645678901', 'Pediatrics', 'docKhadijaArache.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (5, 'Lamiae Bennani', 'lamiae.bennani@medsync.com', '0656789012', 'Neurology', 'docLamiaeBennani.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (6, 'Nabil Azizi', 'nabil.azizi@medsync.com', '0667890123', 'Orthopedics', 'docNabilAzizi.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (7, 'Rachid Mezian', 'rachid.mezian@medsync.com', '0678901234', 'Urology', 'docRachidMezian.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (8, 'Safaa Lbyed', 'safaa.lbyed@medsync.com', '0689012345', 'Ophthalmology', 'docSafaaLbyed.png') ON CONFLICT DO NOTHING;
INSERT INTO public.doctors (id, full_name, email, phone, specialty, profile_picture) VALUES (9, 'Zineb Alaoui', 'zineb.alaoui@medsync.com', '0690123456', 'Psychiatry', 'docZinebAlaoui.png') ON CONFLICT DO NOTHING;


--
-- TOC entry 3788 (class 0 OID 16827)
-- Dependencies: 234
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3786 (class 0 OID 16815)
-- Dependencies: 232
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3774 (class 0 OID 16711)
-- Dependencies: 220
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (1, 1, 'Dr. Ali Rayhi', NULL, 'Cardiology', NULL, NULL, NULL, NULL, 'docAliRayhi.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (2, 2, 'Dr. Asmae Khamlichi', NULL, 'Dermatology', NULL, NULL, NULL, NULL, 'docAsmaekhamlichi.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (3, 3, 'Dr. Houssam Moutarajji', NULL, 'Endocrinology', NULL, NULL, NULL, NULL, 'docHoussamMoutarajji.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (4, 4, 'Dr. Khadija Arache', NULL, 'Pediatrics', NULL, NULL, NULL, NULL, 'docKhadijaArache.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (5, 5, 'Dr. Lamiae Bennani', NULL, 'Neurology', NULL, NULL, NULL, NULL, 'docLamiaeBennani.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (6, 6, 'Dr. Nabil Azizi', NULL, 'Orthopedics', NULL, NULL, NULL, NULL, 'docNabilAzizi.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (7, 7, 'Dr. Rachid Mezian', NULL, 'Urology', NULL, NULL, NULL, NULL, 'docRachidMezian.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (8, 8, 'Dr. Safaa Lbyed', NULL, 'Ophthalmology', NULL, NULL, NULL, NULL, 'docSafaaLbyed.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, user_id, full_name, phone, specialty, experience_years, bio, address, city, profile_picture, created_at, updated_at) VALUES (9, 9, 'Dr. Zineb Alaoui', NULL, 'Psychiatry', NULL, NULL, NULL, NULL, 'docZinebAlaoui.png', '2025-05-16 15:21:03.305384+00', '2025-05-16 15:21:03.305384+00') ON CONFLICT DO NOTHING;


--
-- TOC entry 3784 (class 0 OID 16803)
-- Dependencies: 230
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3772 (class 0 OID 16696)
-- Dependencies: 218
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (1, 'ali.rayhi@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (2, 'asmae.khamlichi@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (3, 'houssam.moutarajji@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (4, 'khadija.arache@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (5, 'lamiae.bennani@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (6, 'nabil.azizi@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (7, 'rachid.mezian@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (8, 'safaa.lbyed@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.users (id, email, password, role, is_active, created_at, updated_at, full_name) VALUES (9, 'zineb.alaoui@medsync.com', 'password123', 'doctor', true, '2025-05-16 15:20:45.145125+00', '2025-05-16 15:20:45.145125+00', NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 3819 (class 0 OID 0)
-- Dependencies: 237
-- Name: Appointments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Appointments_id_seq"', 1, false);


--
-- TOC entry 3820 (class 0 OID 0)
-- Dependencies: 243
-- Name: Messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Messages_id_seq"', 1, false);


--
-- TOC entry 3821 (class 0 OID 0)
-- Dependencies: 241
-- Name: Notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Notifications_id_seq"', 1, false);


--
-- TOC entry 3822 (class 0 OID 0)
-- Dependencies: 239
-- Name: Reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Reviews_id_seq"', 1, false);


--
-- TOC entry 3823 (class 0 OID 0)
-- Dependencies: 235
-- Name: Users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Users_id_seq"', 1, false);


--
-- TOC entry 3824 (class 0 OID 0)
-- Dependencies: 227
-- Name: appointments_email_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_email_id_seq', 1, false);


--
-- TOC entry 3825 (class 0 OID 0)
-- Dependencies: 221
-- Name: appointments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_id_seq', 1, false);


--
-- TOC entry 3826 (class 0 OID 0)
-- Dependencies: 223
-- Name: doctor_availability_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctor_availability_id_seq', 1, false);


--
-- TOC entry 3827 (class 0 OID 0)
-- Dependencies: 225
-- Name: doctors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctors_id_seq', 18, true);


--
-- TOC entry 3828 (class 0 OID 0)
-- Dependencies: 233
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 1, false);


--
-- TOC entry 3829 (class 0 OID 0)
-- Dependencies: 231
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- TOC entry 3830 (class 0 OID 0)
-- Dependencies: 219
-- Name: profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profiles_id_seq', 9, true);


--
-- TOC entry 3831 (class 0 OID 0)
-- Dependencies: 229
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reviews_id_seq', 1, false);


--
-- TOC entry 3832 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 9, true);


--
-- TOC entry 3609 (class 2606 OID 16894)
-- Name: Appointments Appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "Appointments_pkey" PRIMARY KEY (id);


--
-- TOC entry 3615 (class 2606 OID 16933)
-- Name: Messages Messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT "Messages_pkey" PRIMARY KEY (id);


--
-- TOC entry 3613 (class 2606 OID 16923)
-- Name: Notifications Notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "Notifications_pkey" PRIMARY KEY (id);


--
-- TOC entry 3611 (class 2606 OID 16908)
-- Name: Reviews Reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_pkey" PRIMARY KEY (id);


--
-- TOC entry 3605 (class 2606 OID 16876)
-- Name: Users Users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_email_key" UNIQUE (email);


--
-- TOC entry 3607 (class 2606 OID 16874)
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY (id);


--
-- TOC entry 3597 (class 2606 OID 16801)
-- Name: appointments_email appointments_email_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments_email
    ADD CONSTRAINT appointments_email_pkey PRIMARY KEY (id);


--
-- TOC entry 3584 (class 2606 OID 16738)
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- TOC entry 3589 (class 2606 OID 16761)
-- Name: doctor_availability doctor_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability
    ADD CONSTRAINT doctor_availability_pkey PRIMARY KEY (id);


--
-- TOC entry 3593 (class 2606 OID 16788)
-- Name: doctors doctors_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_email_key UNIQUE (email);


--
-- TOC entry 3595 (class 2606 OID 16786)
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (id);


--
-- TOC entry 3603 (class 2606 OID 16837)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3601 (class 2606 OID 16825)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3582 (class 2606 OID 16720)
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 3599 (class 2606 OID 16813)
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 3577 (class 2606 OID 16709)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3579 (class 2606 OID 16707)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3585 (class 1259 OID 16770)
-- Name: idx_appointments_doctor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_doctor_id ON public.appointments USING btree (doctor_id);


--
-- TOC entry 3586 (class 1259 OID 16769)
-- Name: idx_appointments_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_patient_id ON public.appointments USING btree (patient_id);


--
-- TOC entry 3587 (class 1259 OID 16771)
-- Name: idx_appointments_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_start_time ON public.appointments USING btree (start_time);


--
-- TOC entry 3590 (class 1259 OID 16773)
-- Name: idx_doctor_availability_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctor_availability_day ON public.doctor_availability USING btree (day_of_week);


--
-- TOC entry 3591 (class 1259 OID 16772)
-- Name: idx_doctor_availability_doctor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctor_availability_doctor_id ON public.doctor_availability USING btree (doctor_id);


--
-- TOC entry 3580 (class 1259 OID 16768)
-- Name: idx_profiles_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_user_id ON public.profiles USING btree (user_id);


--
-- TOC entry 3575 (class 1259 OID 16767)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 3624 (class 2620 OID 16777)
-- Name: appointments update_appointments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3625 (class 2620 OID 16778)
-- Name: doctor_availability update_doctor_availability_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_doctor_availability_updated_at BEFORE UPDATE ON public.doctor_availability FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3623 (class 2620 OID 16776)
-- Name: profiles update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3622 (class 2620 OID 16775)
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3620 (class 2606 OID 16895)
-- Name: Appointments Appointments_doctorEmail_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "Appointments_doctorEmail_fkey" FOREIGN KEY ("doctorEmail") REFERENCES public.doctors(email) ON UPDATE CASCADE;


--
-- TOC entry 3621 (class 2606 OID 16909)
-- Name: Reviews Reviews_doctorEmail_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reviews"
    ADD CONSTRAINT "Reviews_doctorEmail_fkey" FOREIGN KEY ("doctorEmail") REFERENCES public.doctors(email) ON UPDATE CASCADE;


--
-- TOC entry 3617 (class 2606 OID 16744)
-- Name: appointments appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- TOC entry 3618 (class 2606 OID 16739)
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- TOC entry 3619 (class 2606 OID 16762)
-- Name: doctor_availability doctor_availability_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability
    ADD CONSTRAINT doctor_availability_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 3616 (class 2606 OID 16721)
-- Name: profiles profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-05-19 12:26:13 +01

--
-- PostgreSQL database dump complete
--

