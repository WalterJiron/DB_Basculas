USE Bascula;

GO

CREATE PROC ProcDeleteRol
    @CodigoRol UNIQUEIDENTIFIER,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @CodigoRol IS NULL
        BEGIN
            SET @Mensaje = 'El codigo de rol es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado 
        DECLARE @existRol BIT;
        SET @existRol = (
            SELECT EstadoRol FROM Rol WITH (UPDLOCK, HOLDLOCK) 
            WHERE CodigoRol = @CodigoRol
        );

        IF @existRol IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El rol no existe en la base de datos';
            RETURN;
        END

        IF @existRol = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El rol ya se encuentra eliminado';
            RETURN;
        END

        -- Verificar si hay usuarios asociados al rol
        IF EXISTS (SELECT 1 FROM Users WITH (UPDLOCK) WHERE Rol = @CodigoRol AND EstadoUser = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede eliminar, existen usuarios activos con este rol';
            RETURN;
        END

        UPDATE Rol SET 
            EstadoRol = 0, 
            DateDelete = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
        WHERE CodigoRol = @CodigoRol;

        -- Validar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar el rol';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Rol desactivado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
          
        SET @Mensaje = 'Error al desactivar rol: ' + ERROR_MESSAGE();
    END CATCH
END;