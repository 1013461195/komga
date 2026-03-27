CREATE TABLE TASK
(
    ID                 text      NOT NULL PRIMARY KEY,
    PRIORITY           integer   NOT NULL,
    GROUP_ID           text      NULL,
    CLASS              text      NOT NULL,
    SIMPLE_TYPE        text      NOT NULL,
    PAYLOAD            text      NOT NULL,
    OWNER              text      NULL,
    CREATED_DATE       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx__tasks__owner_group_id ON TASK (OWNER, GROUP_ID);
