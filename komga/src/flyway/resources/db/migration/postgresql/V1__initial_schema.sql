CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- LIBRARY
CREATE TABLE LIBRARY
(
    ID                                    text        NOT NULL PRIMARY KEY,
    CREATED_DATE                          timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE                    timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NAME                                  text        NOT NULL,
    ROOT                                  text        NOT NULL,
    IMPORT_COMICINFO_BOOK                 boolean     NOT NULL DEFAULT true,
    IMPORT_COMICINFO_SERIES               boolean     NOT NULL DEFAULT true,
    IMPORT_COMICINFO_COLLECTION           boolean     NOT NULL DEFAULT true,
    IMPORT_EPUB_BOOK                      boolean     NOT NULL DEFAULT true,
    IMPORT_EPUB_SERIES                    boolean     NOT NULL DEFAULT true,
    SCAN_FORCE_MODIFIED_TIME              boolean     NOT NULL DEFAULT false,
    IMPORT_LOCAL_ARTWORK                  boolean     NOT NULL DEFAULT true,
    IMPORT_COMICINFO_READLIST             boolean     NOT NULL DEFAULT true,
    IMPORT_BARCODE_ISBN                   boolean     NOT NULL DEFAULT true,
    CONVERT_TO_CBZ                        boolean     NOT NULL DEFAULT false,
    REPAIR_EXTENSIONS                     boolean     NOT NULL DEFAULT false,
    EMPTY_TRASH_AFTER_SCAN                boolean     NOT NULL DEFAULT false,
    IMPORT_MYLAR_SERIES                   boolean     NOT NULL DEFAULT true,
    SERIES_COVER                          text        NOT NULL DEFAULT 'FIRST',
    UNAVAILABLE_DATE                      timestamp   NULL,
    HASH_FILES                            boolean     NOT NULL DEFAULT true,
    HASH_PAGES                            boolean     NOT NULL DEFAULT true,
    ANALYZE_DIMENSIONS                    boolean     NOT NULL DEFAULT true,
    IMPORT_COMICINFO_SERIES_APPEND_VOLUME boolean     NOT NULL DEFAULT true,
    SCAN_STARTUP                          boolean     NOT NULL DEFAULT false,
    SCAN_CBX                              boolean     NOT NULL DEFAULT true,
    SCAN_PDF                              boolean     NOT NULL DEFAULT true,
    SCAN_EPUB                             boolean     NOT NULL DEFAULT true,
    SCAN_INTERVAL                         text        NOT NULL DEFAULT 'EVERY_6H',
    ONESHOTS_DIRECTORY                    boolean     NOT NULL DEFAULT false,
    HASH_KOREADER                         boolean     NOT NULL DEFAULT false
);

-- USER
CREATE TABLE "USER"
(
    ID                          text        NOT NULL PRIMARY KEY,
    CREATED_DATE                timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE          timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    EMAIL                       text        NOT NULL UNIQUE,
    PASSWORD                    text        NOT NULL,
    SHARED_ALL_LIBRARIES        boolean     NOT NULL DEFAULT true,
    AGE_RESTRICTION             integer     NULL,
    AGE_RESTRICTION_ALLOW_ONLY  boolean     NOT NULL DEFAULT false
);

CREATE TABLE USER_ROLE
(
    USER_ID text NOT NULL,
    ROLE    text NOT NULL,
    PRIMARY KEY (USER_ID, ROLE),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);

CREATE TABLE USER_LIBRARY_SHARING
(
    USER_ID    text NOT NULL,
    LIBRARY_ID text NOT NULL,
    PRIMARY KEY (USER_ID, LIBRARY_ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID),
    FOREIGN KEY (LIBRARY_ID) REFERENCES LIBRARY (ID)
);

CREATE TABLE USER_SHARING
(
    LABEL   text NOT NULL,
    ALLOW   text NOT NULL,
    USER_ID text NOT NULL,
    PRIMARY KEY (LABEL, ALLOW, USER_ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);

CREATE TABLE USER_API_KEY
(
    ID                 text        NOT NULL PRIMARY KEY,
    USER_ID            text        NOT NULL,
    CREATED_DATE       timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    API_KEY            text        NOT NULL UNIQUE,
    COMMENT            text        NOT NULL,
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);
CREATE INDEX idx__user_api_key__user_id ON USER_API_KEY (USER_ID);

-- SERIES
CREATE TABLE SERIES
(
    ID                 text        NOT NULL PRIMARY KEY,
    CREATED_DATE       timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FILE_LAST_MODIFIED timestamp   NOT NULL,
    NAME               text        NOT NULL,
    URL                text        NOT NULL,
    LIBRARY_ID         text        NOT NULL,
    BOOK_COUNT         integer     NOT NULL DEFAULT 0,
    DELETED_DATE       timestamp   NULL,
    ONESHOT            boolean     NOT NULL DEFAULT false,
    FOREIGN KEY (LIBRARY_ID) REFERENCES LIBRARY (ID)
);
CREATE INDEX idx__series__library_id ON SERIES (LIBRARY_ID);
CREATE INDEX idx__series__last_modified_date ON SERIES (LAST_MODIFIED_DATE);
CREATE INDEX idx__series__created_date ON SERIES (CREATED_DATE);

CREATE TABLE SERIES_METADATA
(
    CREATED_DATE         timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE   timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    STATUS               text      NOT NULL,
    STATUS_LOCK          boolean   NOT NULL DEFAULT false,
    TITLE                text      NOT NULL,
    TITLE_LOCK           boolean   NOT NULL DEFAULT false,
    TITLE_SORT           text      NOT NULL,
    TITLE_SORT_LOCK      boolean   NOT NULL DEFAULT false,
    SERIES_ID            text      NOT NULL PRIMARY KEY,
    PUBLISHER            text      NOT NULL DEFAULT '',
    PUBLISHER_LOCK       boolean   NOT NULL DEFAULT false,
    READING_DIRECTION    text      NULL,
    READING_DIRECTION_LOCK boolean NOT NULL DEFAULT false,
    AGE_RATING           integer   NULL,
    AGE_RATING_LOCK      boolean   NOT NULL DEFAULT false,
    SUMMARY              text      NOT NULL DEFAULT '',
    SUMMARY_LOCK         boolean   NOT NULL DEFAULT false,
    LANGUAGE             text      NOT NULL DEFAULT '',
    LANGUAGE_LOCK        boolean   NOT NULL DEFAULT false,
    GENRES_LOCK          boolean   NOT NULL DEFAULT false,
    TAGS_LOCK            boolean   NOT NULL DEFAULT false,
    TOTAL_BOOK_COUNT     integer   NULL,
    TOTAL_BOOK_COUNT_LOCK boolean  NOT NULL DEFAULT false,
    SHARING_LABELS_LOCK  boolean   NOT NULL DEFAULT false,
    LINKS_LOCK           boolean   NOT NULL DEFAULT false,
    ALTERNATE_TITLES_LOCK boolean  NOT NULL DEFAULT false,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata__title ON SERIES_METADATA (TITLE);

CREATE TABLE SERIES_METADATA_GENRE
(
    GENRE     text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata_genre__series_id ON SERIES_METADATA_GENRE (SERIES_ID);

CREATE TABLE SERIES_METADATA_TAG
(
    TAG       text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata_tag__series_id ON SERIES_METADATA_TAG (SERIES_ID);

CREATE TABLE SERIES_METADATA_SHARING
(
    LABEL     text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata_sharing__series_id ON SERIES_METADATA_SHARING (SERIES_ID);

CREATE TABLE SERIES_METADATA_LINK
(
    LABEL     text NOT NULL,
    URL       text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata_link__series_id ON SERIES_METADATA_LINK (SERIES_ID);

CREATE TABLE SERIES_METADATA_ALTERNATE_TITLE
(
    LABEL     text NOT NULL,
    TITLE     text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__series_metadata_alternate_title__series_id ON SERIES_METADATA_ALTERNATE_TITLE (SERIES_ID);

-- BOOK
CREATE TABLE BOOK
(
    ID                 text        NOT NULL PRIMARY KEY,
    CREATED_DATE       timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FILE_LAST_MODIFIED timestamp   NOT NULL,
    NAME               text        NOT NULL,
    URL                text        NOT NULL,
    SERIES_ID          text        NOT NULL,
    FILE_SIZE          bigint      NOT NULL DEFAULT 0,
    NUMBER             integer     NOT NULL DEFAULT 0,
    LIBRARY_ID         text        NOT NULL,
    FILE_HASH          text        NOT NULL DEFAULT '',
    DELETED_DATE       timestamp   NULL,
    ONESHOT            boolean     NOT NULL DEFAULT false,
    FILE_HASH_KOREADER text        NOT NULL DEFAULT '',
    FOREIGN KEY (LIBRARY_ID) REFERENCES LIBRARY (ID),
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__book__series_id ON BOOK (SERIES_ID);
CREATE INDEX idx__book__library_id ON BOOK (LIBRARY_ID);
CREATE INDEX idx__book__created_date ON BOOK (CREATED_DATE);

CREATE TABLE BOOK_METADATA
(
    CREATED_DATE       timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NUMBER             text        NOT NULL,
    NUMBER_LOCK        boolean     NOT NULL DEFAULT false,
    NUMBER_SORT        real        NOT NULL,
    NUMBER_SORT_LOCK   boolean     NOT NULL DEFAULT false,
    RELEASE_DATE       date        NULL,
    RELEASE_DATE_LOCK  boolean     NOT NULL DEFAULT false,
    SUMMARY            text        NOT NULL DEFAULT '',
    SUMMARY_LOCK       boolean     NOT NULL DEFAULT false,
    TITLE              text        NOT NULL,
    TITLE_LOCK         boolean     NOT NULL DEFAULT false,
    AUTHORS_LOCK       boolean     NOT NULL DEFAULT false,
    TAGS_LOCK          boolean     NOT NULL DEFAULT false,
    BOOK_ID            text        NOT NULL PRIMARY KEY,
    ISBN               text        NOT NULL DEFAULT '',
    ISBN_LOCK          boolean     NOT NULL DEFAULT false,
    LINKS_LOCK         boolean     NOT NULL DEFAULT false,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__book_metadata__number_sort ON BOOK_METADATA (NUMBER_SORT);
CREATE INDEX idx__book_metadata__release_date ON BOOK_METADATA (RELEASE_DATE);

CREATE TABLE BOOK_METADATA_AUTHOR
(
    NAME    text NOT NULL,
    ROLE    text NOT NULL,
    BOOK_ID text NOT NULL,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__book_metadata_author__book_id ON BOOK_METADATA_AUTHOR (BOOK_ID);

CREATE TABLE BOOK_METADATA_TAG
(
    TAG     text NOT NULL,
    BOOK_ID text NOT NULL,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__book_metadata_tag__book_id ON BOOK_METADATA_TAG (BOOK_ID);

CREATE TABLE BOOK_METADATA_LINK
(
    LABEL   text NOT NULL,
    URL     text NOT NULL,
    BOOK_ID text NOT NULL,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__book_metadata_link__book_id ON BOOK_METADATA_LINK (BOOK_ID);

CREATE TABLE BOOK_METADATA_AGGREGATION
(
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    RELEASE_DATE       date      NULL,
    SUMMARY            text      NOT NULL DEFAULT '',
    SUMMARY_NUMBER     text      NOT NULL DEFAULT '',
    SERIES_ID          text      NOT NULL PRIMARY KEY,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);

CREATE TABLE BOOK_METADATA_AGGREGATION_AUTHOR
(
    NAME      text NOT NULL,
    ROLE      text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__book_metadata_aggregation_author__series_id ON BOOK_METADATA_AGGREGATION_AUTHOR (SERIES_ID);

CREATE TABLE BOOK_METADATA_AGGREGATION_TAG
(
    TAG       text NOT NULL,
    SERIES_ID text NOT NULL,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__book_metadata_aggregation_tag__series_id ON BOOK_METADATA_AGGREGATION_TAG (SERIES_ID);

-- MEDIA
CREATE TABLE MEDIA
(
    MEDIA_TYPE              text      NULL,
    STATUS                  text      NOT NULL,
    CREATED_DATE            timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE      timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    COMMENT                 text      NULL,
    BOOK_ID                 text      NOT NULL PRIMARY KEY,
    PAGE_COUNT              integer   NOT NULL DEFAULT 0,
    EXTENSION_CLASS         text      NULL,
    EXTENSION_VALUE_BLOB    bytea     NULL,
    EPUB_DIVINA_COMPATIBLE  boolean   NOT NULL DEFAULT false,
    EPUB_IS_KEPUB           boolean   NOT NULL DEFAULT false,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__media__status ON MEDIA (STATUS);

CREATE TABLE MEDIA_PAGE
(
    FILE_NAME  text    NOT NULL,
    MEDIA_TYPE text    NOT NULL,
    NUMBER     integer NOT NULL,
    BOOK_ID    text    NOT NULL,
    WIDTH      integer NOT NULL DEFAULT 0,
    HEIGHT     integer NOT NULL DEFAULT 0,
    FILE_HASH  text    NOT NULL DEFAULT '',
    FILE_SIZE  bigint  NOT NULL DEFAULT 0,
    PRIMARY KEY (BOOK_ID, NUMBER),
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);

CREATE TABLE MEDIA_FILE
(
    FILE_NAME  text    NOT NULL,
    BOOK_ID    text    NOT NULL,
    MEDIA_TYPE text    NOT NULL DEFAULT '',
    SUB_TYPE   text    NOT NULL DEFAULT '',
    FILE_SIZE  bigint  NOT NULL DEFAULT 0,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__media_file__book_id ON MEDIA_FILE (BOOK_ID);

-- READ PROGRESS
CREATE TABLE READ_PROGRESS
(
    BOOK_ID            text      NOT NULL,
    USER_ID            text      NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PAGE               integer   NOT NULL,
    COMPLETED          boolean   NOT NULL,
    READ_DATE          timestamp NULL,
    DEVICE_ID          text      NULL,
    DEVICE_NAME        text      NULL,
    LOCATOR            bytea     NULL,
    PRIMARY KEY (BOOK_ID, USER_ID),
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);
CREATE INDEX idx__read_progress__last_modified_date ON READ_PROGRESS (LAST_MODIFIED_DATE);

CREATE TABLE READ_PROGRESS_SERIES
(
    SERIES_ID            text      NOT NULL,
    USER_ID              text      NOT NULL,
    READ_COUNT           integer   NOT NULL DEFAULT 0,
    IN_PROGRESS_COUNT    integer   NOT NULL DEFAULT 0,
    MOST_RECENT_READ_DATE timestamp NULL,
    LAST_MODIFIED_DATE   timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (SERIES_ID, USER_ID),
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);

-- COLLECTIONS
CREATE TABLE COLLECTION
(
    ID                 text      NOT NULL PRIMARY KEY,
    NAME               text      NOT NULL,
    ORDERED            boolean   NOT NULL DEFAULT false,
    SERIES_COUNT       integer   NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE COLLECTION_SERIES
(
    COLLECTION_ID text    NOT NULL,
    SERIES_ID     text    NOT NULL,
    NUMBER        integer NOT NULL,
    PRIMARY KEY (COLLECTION_ID, SERIES_ID),
    FOREIGN KEY (COLLECTION_ID) REFERENCES COLLECTION (ID),
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);

-- READ LISTS
CREATE TABLE READLIST
(
    ID                 text      NOT NULL PRIMARY KEY,
    NAME               text      NOT NULL,
    BOOK_COUNT         integer   NOT NULL DEFAULT 0,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SUMMARY            text      NOT NULL DEFAULT '',
    ORDERED            boolean   NOT NULL DEFAULT true
);

CREATE TABLE READLIST_BOOK
(
    READLIST_ID text    NOT NULL,
    BOOK_ID     text    NOT NULL,
    NUMBER      integer NOT NULL,
    PRIMARY KEY (READLIST_ID, BOOK_ID),
    FOREIGN KEY (READLIST_ID) REFERENCES READLIST (ID),
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);

-- THUMBNAILS
CREATE TABLE THUMBNAIL_BOOK
(
    ID                 text      NOT NULL PRIMARY KEY,
    THUMBNAIL          bytea     NULL,
    URL                text      NULL,
    SELECTED           boolean   NOT NULL DEFAULT false,
    TYPE               text      NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    BOOK_ID            text      NOT NULL,
    WIDTH              integer   NOT NULL DEFAULT 0,
    HEIGHT             integer   NOT NULL DEFAULT 0,
    MEDIA_TYPE         text      NULL,
    FILE_SIZE          bigint    NOT NULL DEFAULT 0,
    FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID)
);
CREATE INDEX idx__thumbnail_book__book_id ON THUMBNAIL_BOOK (BOOK_ID);
CREATE INDEX idx__thumbnail_book__width ON THUMBNAIL_BOOK (WIDTH);
CREATE INDEX idx__thumbnail_book__height ON THUMBNAIL_BOOK (HEIGHT);
CREATE INDEX idx__thumbnail_book__file_size ON THUMBNAIL_BOOK (FILE_SIZE);

CREATE TABLE THUMBNAIL_SERIES
(
    ID                 text      NOT NULL PRIMARY KEY,
    URL                text      NULL,
    SELECTED           boolean   NOT NULL DEFAULT false,
    THUMBNAIL          bytea     NULL,
    TYPE               text      NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SERIES_ID          text      NOT NULL,
    WIDTH              integer   NOT NULL DEFAULT 0,
    HEIGHT             integer   NOT NULL DEFAULT 0,
    MEDIA_TYPE         text      NULL,
    FILE_SIZE          bigint    NOT NULL DEFAULT 0,
    FOREIGN KEY (SERIES_ID) REFERENCES SERIES (ID)
);
CREATE INDEX idx__thumbnail_series__series_id ON THUMBNAIL_SERIES (SERIES_ID);

CREATE TABLE THUMBNAIL_COLLECTION
(
    ID                 text      NOT NULL PRIMARY KEY,
    SELECTED           boolean   NOT NULL DEFAULT false,
    THUMBNAIL          bytea     NOT NULL,
    TYPE               text      NOT NULL,
    COLLECTION_ID      text      NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    WIDTH              integer   NOT NULL DEFAULT 0,
    HEIGHT             integer   NOT NULL DEFAULT 0,
    MEDIA_TYPE         text      NULL,
    FILE_SIZE          bigint    NOT NULL DEFAULT 0,
    FOREIGN KEY (COLLECTION_ID) REFERENCES COLLECTION (ID)
);
CREATE INDEX idx__thumbnail_collection__collection_id ON THUMBNAIL_COLLECTION (COLLECTION_ID);

CREATE TABLE THUMBNAIL_READLIST
(
    ID                 text      NOT NULL PRIMARY KEY,
    SELECTED           boolean   NOT NULL DEFAULT false,
    THUMBNAIL          bytea     NOT NULL,
    TYPE               text      NOT NULL,
    READLIST_ID        text      NOT NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    WIDTH              integer   NOT NULL DEFAULT 0,
    HEIGHT             integer   NOT NULL DEFAULT 0,
    MEDIA_TYPE         text      NULL,
    FILE_SIZE          bigint    NOT NULL DEFAULT 0,
    FOREIGN KEY (READLIST_ID) REFERENCES READLIST (ID)
);
CREATE INDEX idx__thumbnail_readlist__readlist_id ON THUMBNAIL_READLIST (READLIST_ID);

-- SIDECAR
CREATE TABLE SIDECAR
(
    URL                text      NOT NULL PRIMARY KEY,
    PARENT_URL         text      NOT NULL,
    LAST_MODIFIED_TIME timestamp NOT NULL,
    LIBRARY_ID         text      NOT NULL
);

-- AUTHENTICATION ACTIVITY
CREATE TABLE AUTHENTICATION_ACTIVITY
(
    USER_ID         text      NULL,
    EMAIL           text      NULL,
    IP              text      NULL,
    USER_AGENT      text      NULL,
    SUCCESS         boolean   NOT NULL,
    ERROR           text      NULL,
    DATE_TIME       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SOURCE          text      NULL,
    API_KEY_ID      text      NULL,
    API_KEY_COMMENT text      NULL,
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);
CREATE INDEX idx__authentication_activity__user_id ON AUTHENTICATION_ACTIVITY (USER_ID);

-- HISTORICAL EVENTS
CREATE TABLE HISTORICAL_EVENT
(
    ID        text      NOT NULL PRIMARY KEY,
    TYPE      text      NOT NULL,
    BOOK_ID   text      NULL,
    SERIES_ID text      NULL,
    TIMESTAMP timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE HISTORICAL_EVENT_PROPERTIES
(
    ID    text NOT NULL,
    KEY   text NOT NULL,
    VALUE text NOT NULL,
    PRIMARY KEY (ID, KEY),
    FOREIGN KEY (ID) REFERENCES HISTORICAL_EVENT (ID)
);

-- PAGE HASH
CREATE TABLE PAGE_HASH
(
    HASH               text      NOT NULL PRIMARY KEY,
    SIZE               bigint    NOT NULL,
    ACTION             text      NULL,
    DELETE_COUNT        integer   NOT NULL DEFAULT 0,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PAGE_HASH_THUMBNAIL
(
    HASH      text  NOT NULL PRIMARY KEY,
    THUMBNAIL bytea NOT NULL
);

-- ANNOUNCEMENTS
CREATE TABLE ANNOUNCEMENTS_READ
(
    USER_ID         text NOT NULL,
    ANNOUNCEMENT_ID text NOT NULL,
    PRIMARY KEY (USER_ID, ANNOUNCEMENT_ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);

-- LIBRARY EXCLUSIONS
CREATE TABLE LIBRARY_EXCLUSIONS
(
    LIBRARY_ID text NOT NULL,
    EXCLUSION  text NOT NULL,
    PRIMARY KEY (LIBRARY_ID, EXCLUSION),
    FOREIGN KEY (LIBRARY_ID) REFERENCES LIBRARY (ID)
);
CREATE INDEX idx__library_exclusions__library_id ON LIBRARY_EXCLUSIONS (LIBRARY_ID);

-- SERVER SETTINGS
CREATE TABLE SERVER_SETTINGS
(
    KEY   text NOT NULL PRIMARY KEY,
    VALUE text NOT NULL
);
INSERT INTO SERVER_SETTINGS (KEY, VALUE) VALUES ('REMEMBER_ME_KEY', encode(gen_random_bytes(32), 'hex'));
INSERT INTO SERVER_SETTINGS (KEY, VALUE) VALUES ('DELETE_EMPTY_COLLECTIONS', '${delete-empty-collections}');
INSERT INTO SERVER_SETTINGS (KEY, VALUE) VALUES ('DELETE_EMPTY_READ_LISTS', '${delete-empty-read-lists}');

-- SYNC POINT
CREATE TABLE SYNC_POINT
(
    ID           text      NOT NULL PRIMARY KEY,
    CREATED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    USER_ID      text      NOT NULL,
    API_KEY_ID   text      NULL,
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);
CREATE INDEX idx__sync_point__user_id ON SYNC_POINT (USER_ID);

CREATE TABLE SYNC_POINT_BOOK
(
    SYNC_POINT_ID                       text      NOT NULL,
    BOOK_ID                             text      NOT NULL,
    BOOK_CREATED_DATE                   timestamp NOT NULL,
    BOOK_LAST_MODIFIED_DATE             timestamp NOT NULL,
    BOOK_FILE_LAST_MODIFIED             timestamp NOT NULL,
    BOOK_FILE_SIZE                      bigint    NOT NULL,
    BOOK_FILE_HASH                      text      NOT NULL DEFAULT '',
    BOOK_METADATA_LAST_MODIFIED_DATE    timestamp NOT NULL,
    BOOK_READ_PROGRESS_LAST_MODIFIED_DATE timestamp NULL,
    SYNCED                              boolean   NOT NULL DEFAULT false,
    BOOK_THUMBNAIL_ID                   text      NULL,
    PRIMARY KEY (SYNC_POINT_ID, BOOK_ID),
    FOREIGN KEY (SYNC_POINT_ID) REFERENCES SYNC_POINT (ID)
);
CREATE INDEX idx__sync_point_book__sync_point_id ON SYNC_POINT_BOOK (SYNC_POINT_ID);

CREATE TABLE SYNC_POINT_BOOK_REMOVED_SYNCED
(
    SYNC_POINT_ID text NOT NULL,
    BOOK_ID       text NOT NULL,
    PRIMARY KEY (SYNC_POINT_ID, BOOK_ID),
    FOREIGN KEY (SYNC_POINT_ID) REFERENCES SYNC_POINT (ID)
);
CREATE INDEX idx__sync_point_book_removed_status__sync_point_id ON SYNC_POINT_BOOK_REMOVED_SYNCED (SYNC_POINT_ID);

CREATE TABLE SYNC_POINT_READLIST
(
    SYNC_POINT_ID              text      NOT NULL,
    READLIST_ID                text      NOT NULL,
    READLIST_NAME              text      NOT NULL,
    READLIST_CREATED_DATE      timestamp NOT NULL,
    READLIST_LAST_MODIFIED_DATE timestamp NOT NULL,
    SYNCED                     boolean   NOT NULL DEFAULT false,
    PRIMARY KEY (SYNC_POINT_ID, READLIST_ID),
    FOREIGN KEY (SYNC_POINT_ID) REFERENCES SYNC_POINT (ID)
);
CREATE INDEX idx__sync_point_readlist__sync_point_id ON SYNC_POINT_READLIST (SYNC_POINT_ID);

CREATE TABLE SYNC_POINT_READLIST_BOOK
(
    SYNC_POINT_ID text NOT NULL,
    READLIST_ID   text NOT NULL,
    BOOK_ID       text NOT NULL,
    PRIMARY KEY (SYNC_POINT_ID, READLIST_ID, BOOK_ID),
    FOREIGN KEY (SYNC_POINT_ID) REFERENCES SYNC_POINT (ID)
);
CREATE INDEX idx__sync_point_readlist_book__sync_point_id_readlist_id ON SYNC_POINT_READLIST_BOOK (SYNC_POINT_ID, READLIST_ID);

CREATE TABLE SYNC_POINT_READLIST_REMOVED_SYNCED
(
    SYNC_POINT_ID text NOT NULL,
    READLIST_ID   text NOT NULL,
    PRIMARY KEY (SYNC_POINT_ID, READLIST_ID),
    FOREIGN KEY (SYNC_POINT_ID) REFERENCES SYNC_POINT (ID)
);

-- CLIENT SETTINGS
CREATE TABLE CLIENT_SETTINGS_GLOBAL
(
    KEY                text    NOT NULL PRIMARY KEY,
    VALUE              text    NOT NULL,
    ALLOW_UNAUTHORIZED boolean NOT NULL DEFAULT false
);

CREATE TABLE CLIENT_SETTINGS_USER
(
    USER_ID text NOT NULL,
    KEY     text NOT NULL,
    VALUE   text NOT NULL,
    PRIMARY KEY (KEY, USER_ID),
    FOREIGN KEY (USER_ID) REFERENCES "USER" (ID)
);
