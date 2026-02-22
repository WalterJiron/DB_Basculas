USE Bascula;

GO

CREATE PROC ProcRecoverRol
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

        IF @existRol = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El rol ya se encuentra activo';
            RETURN;
        END

        -- Verificar que el nombre del rol no este siendo usado por otro rol activo
        DECLARE @NombreRol NVARCHAR(50);
        
        SELECT @NombreRol = NombreRol
        FROM Rol WITH (UPDLOCK)
        WHERE CodigoRol = @CodigoRol;

        IF EXISTS (
            SELECT 1 FROM Rol WITH (UPDLOCK)
            WHERE NombreRol = @NombreRol AND CodigoRol <> @CodigoRol
              AND EstadoRol = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe un rol activo con ese nombre';
            RETURN;
        END

        -- Recuperacion del rol
        UPDATE Rol SET 
            EstadoRol = 1, 
            DateDelete = NULL
        WHERE CodigoRol = @CodigoRol;

        -- Validar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar el rol';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Rol recuperado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar rol: ' + ERROR_MESSAGE();
    END CATCH
END;