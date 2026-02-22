USE Bascula;

GO

CREATE PROC ProcDeleteUser
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

        IF @exist_User = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El usuario ya se encuentra inactivo';
            RETURN;
        END

        UPDATE Users SET 
            EstadoUser = 0, 
            DateDelete = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
        WHERE CodigoUser = @CodigoUser;

        -- Validar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar el usuario';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Usuario desactivado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar usuario: ' + ERROR_MESSAGE();
    END CATCH
END;