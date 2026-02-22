USE Bascula;

GO

CREATE PROC ProcUpdateUser
    @CodigoUser UNIQUEIDENTIFIER,
    @NameUser NVARCHAR(50),
    @Email NVARCHAR(100),
    @Clave NVARCHAR(100),
    @Rol UNIQUEIDENTIFIER,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @CodigoUser IS NULL OR @NameUser IS NULL OR @Email IS NULL OR @Rol IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        -- Validacion de nombre de usuario
        IF LEN(TRIM(@NameUser)) < 3 OR LEN(TRIM(@NameUser)) > 50
        BEGIN
            SET @Mensaje = 'El nombre de usuario debe tener al menos 3 caracteres y maximo 50';
            RETURN;
        END

        IF @NameUser LIKE '%[^a-zA-Z0-9 ]%'
        BEGIN
            SET @Mensaje = 'El nombre de usuario solo puede contener letras, numeros y espacios';
            RETURN;
        END

        IF LEN(TRIM(@Email)) < 5 OR LEN(TRIM(@Email)) > 100
        BEGIN
            SET @Mensaje = 'El correo debe tener al menos 5 caracteres y maximo 100';
            RETURN;
        END

        -- Validacion mejorada de formato de email
        IF @Email NOT LIKE '%_@_%._%' OR @Email LIKE '%@%@%' OR 
           @Email NOT LIKE '%.%' OR @Email LIKE '%..%'
        BEGIN
            SET @Mensaje = 'El formato del correo no es valido';
            RETURN;
        END

        -- Validacion de complejidad de clave
        IF @Clave IS NOT NULL 
        BEGIN
            IF LEN(@Clave) < 8
            BEGIN
                SET @Mensaje = 'La clave debe tener al menos 8 caracteres';
                RETURN;
            END

            IF @Clave NOT LIKE '%[0-9]%' OR @Clave NOT LIKE '%[a-z]%' OR
            @Clave NOT LIKE '%[A-Z]%' OR @Clave NOT LIKE '%[^a-zA-Z0-9]%'
            BEGIN
                SET @Mensaje = 'La clave debe contener al menos: 1 numero, 1 mayuscula, 1 minuscula y 1 caracter especial';
                RETURN;
            END
        END

        BEGIN TRANSACTION;

        -- Verificar usuario 
        DECLARE @exist_User BIT;
        SET @exist_User =(
            SELECT EstadoUser FROM Users WITH(UPDLOCK, ROWLOCK)
            WHERE CodigoUser = @CodigoUser
        )

        IF @exist_User IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El usuario no existe en la base de datos';
            RETURN;
        END

        IF @exist_User = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El usuario esta inactivo';
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM Users WITH (UPDLOCK)
            WHERE Email = LOWER(TRIM(@Email))
              AND CodigoUser <> @CodigoUser
              AND EstadoUser = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El correo ya esta registrado por otro usuario activo';
            RETURN;
        END

        -- Verificar existencia de rol 
        DECLARE @rol_exis AS BIT;
        SET @rol_exis = (SELECT EstadoRol FROM Rol WITH(UPDLOCK) WHERE CodigoRol = @Rol);

        IF @rol_exis IS NULL
        BEGIN
            SET @Mensaje = 'EL codigo de rol no existe en la base de datos';
            RETURN;
        END

        IF @rol_exis = 0
        BEGIN
            SET @Mensaje = 'El rol esta inactivo';
            RETURN;
        END

        IF @Clave IS NOT NULL AND @Clave <> ''
        BEGIN
            UPDATE Users SET
                NameUser = TRIM(@NameUser),
                Email = LOWER(TRIM(@Email)),
                Clave = HASHBYTES('SHA2_512', @Clave + LOWER(TRIM(@Email))),
                Rol = @Rol,
                DateUpdate = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
            WHERE CodigoUser = @CodigoUser;
        END ELSE
        BEGIN
            UPDATE Users SET
                NameUser = TRIM(@NameUser),
                Email = LOWER(TRIM(@Email)),
                Rol = @Rol,
                DateUpdate = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
            WHERE CodigoUser = @CodigoUser;
        END

        -- Verificar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar el usuario';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Usuario actualizado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Mensaje = 'Error al actualizar usuario: ' + ERROR_MESSAGE();
    END CATCH
END;