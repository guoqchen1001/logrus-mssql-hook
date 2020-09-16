CREATE TABLE logs (
    id int identity(1,1),
    level smallint NOT NULL,
    message nvarchar(max) NOT NULL,
    message_data nvarchar(max) NOT NULL,
    created_at DateTime  NOT NULL
);
