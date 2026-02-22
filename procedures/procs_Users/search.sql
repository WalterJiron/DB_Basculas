USE Bascula;

GO

CREATE PROC sp_VerificarUsuario
    @Email NVARCHAR(100),
    @Clave NVARCHAR(100),
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(TRIM(@Email)) = 0 OR LEN(TRIM(@Clave)) = 0
    BEGIN
        SET @Mensaje = 'Los campos no pueden estar vacios o nulos';
        RETURN;
    END

    -- Verificamos que el correo este en un formato valido
    IF @Email NOT LIKE '%_@_%._%' OR @Email LIKE '%@%@%' OR 
        @Email NOT LIKE '%.%' OR @Email LIKE '%..%'
    BEGIN
        SET @Mensaje = 'El formato del correo no es valido';
        RETURN;
    END

    -- Buscamos el usuario
    DECLARE @user_exis AS BIT;
    SET @user_exis = (SELECT EstadoUser FROM Users WHERE Email = TRIM(LOWER(@Email)));

    -- Miramos si el correo existe
    IF @user_exis IS NULL
    BEGIN
        SET @Mensaje = 'El correo no existe en la base de datos';
        RETURN;
    END

    -- Miramos que el usuario este activo
    IF @user_exis = 0
    BEGIN
        SET @Mensaje = 'El usuario esta inactivo';
        RETURN;
    END

    -- Miramos que la clave este correcta
    IF NOT EXISTS (
        SELECT 1 FROM Users 
        WHERE Email = TRIM(LOWER(@Email)) 
        AND Clave = HASHBYTES('SHA2_512', @Clave + TRIM(LOWER(@Email)))
    )
    BEGIN
        SET @Mensaje = 'La clave es incorrecta';
        RETURN;
    END

    -- Mandamos el nombre de usuario
    SET @Mensaje = 'OK';

    UPDATE Users SET
        LastLogin = SYSDATETIME()
    WHERE Email = TRIM(LOWER(@Email))
END;