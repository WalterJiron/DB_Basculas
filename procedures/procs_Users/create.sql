USE Bascula;

GO

CREATE PROC ProcInsertUser
    @NameUser NVARCHAR(50),
    @Email NVARCHAR(100),
    @Clave NVARCHAR(100),
    @Rol UNIQUEIDENTIFIER,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @NameUser IS NULL OR @Email IS NULL OR @Clave IS NULL OR @Rol IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

         -- Validacion de nombre de usuario
        IF LEN(TRIM(@NameUser)) < 3 AND LEN(TRIM(@NameUser)) > 50
        BEGIN
            SET @Mensaje = 'El nombre de usuario debe tener al menos 3 caracteres y maximo 50';
            RETURN;
        END

        IF @NameUser LIKE '%[^a-zA-Z0-9 ]%'
        BEGIN
            SET @Mensaje = 'El nombre de usuario solo puede contener letras, numeros y espacios';
            RETURN;
        END

        IF LEN(TRIM(@Email)) < 5 AND LEN(TRIM(@Email)) > 100
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

        BEGIN TRANSACTION;

        -- Verificar email unico con bloqueo
        IF EXISTS (SELECT 1 FROM Users WITH (UPDLOCK, ROWLOCK) WHERE Email = @Email)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El correo ya esta registrado';
            RETURN;
        END

        -- Verificar existencia de rol 
        DECLARE @rol_exis AS BIT;
        SET @rol_exis = (SELECT EstadoRol FROM Rol WITH(UPDLOCK) WHERE CodigoRol = @Rol);

        IF @rol_exis IS NULL
        BEGIN
            ROLLBACK TRANSACTION
            SET @Mensaje = 'EL codigo de rol no existe en la base de datos';
            RETURN;
        END

        IF @rol_exis = 0
        BEGIN
            ROLLBACK TRANSACTION
            SET @Mensaje = 'El rol esta inactivo';
            RETURN;
        END

        -- Insercion principal con hash de contraseña
        INSERT INTO Users (
            NameUser, Email, Clave, Rol
        )
        VALUES (
            TRIM(@NameUser), LOWER(TRIM(@Email)),
            HASHBYTES('SHA2_512', @Clave + LOWER(TRIM(@Email))), 
            @Rol
        );

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error al crear el usuario';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Usuario registrado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Mensaje = 'Error al registrar usuario: ' + ERROR_MESSAGE();
    END CATCH
END;