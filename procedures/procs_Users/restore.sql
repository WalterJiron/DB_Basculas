USE Bascula;

GO

CREATE PROC ProcRecoverUser
    @CodigoUser UNIQUEIDENTIFIER,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @CodigoUser IS NULL
        BEGIN
            SET @Mensaje = 'El codigo de usuario es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Buscar el usuario
        DECLARE @exist_User BIT;
        SET @exist_User = (
            SELECT EstadoUser 
            FROM Users WITH (UPDLOCK, ROWLOCK) 
            WHERE CodigoUser = @CodigoUser
        );

        IF @exist_User IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El usuario no existe en la base de datos';
            RETURN;
        END

        IF @exist_User = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El usuario ya se encuentra activo';
            RETURN;
        END

        -- Verificar que el email no este siendo usado por otro usuario activo
        DECLARE @EmailUsuario NVARCHAR(100);
        SELECT @EmailUsuario = Email
        FROM Users WITH (UPDLOCK)
        WHERE CodigoUser = @CodigoUser;

        IF EXISTS (
            SELECT 1 FROM Users WITH (UPDLOCK)
            WHERE Email = @EmailUsuario AND CodigoUser <> @CodigoUser
              AND EstadoUser = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, el email ya esta en uso por otro usuario activo';
            RETURN;
        END

        UPDATE Users SET 
            EstadoUser = 1, 
            DateDelete = NULL
        WHERE CodigoUser = @CodigoUser;

        -- Validar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar el usuario';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Usuario recuperado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
       SET @Mensaje = 'Error al recuperar usuario: ' + ERROR_MESSAGE();
    END CATCH
END;