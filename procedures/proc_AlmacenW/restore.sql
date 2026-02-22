USE Bascula

GO

CREATE PROC ProcRestoreAlmacen
    @CodAlmacen INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de almacen
        IF @CodAlmacen IS NULL
        BEGIN
            SET @Mensaje = 'El código de almacén es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @NombreAlmacen NVARCHAR(50);
        
        SELECT @EstadoActual = EstadoAlmacen, @NombreAlmacen = NombreAlmacen
        FROM Almacen WITH (UPDLOCK, HOLDLOCK)
        WHERE CodAlmacen = @CodAlmacen;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El almacén no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El almacén ya se encuentra activo';
            RETURN;
        END

        -- Verificar que el nombre no este siendo usado por otro almacen activo
        IF EXISTS (
            SELECT 1 FROM Almacen WITH (UPDLOCK)
            WHERE NombreAlmacen = @NombreAlmacen
              AND CodAlmacen <> @CodAlmacen
              AND EstadoAlmacen = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe un almacén activo con ese nombre';
            RETURN;
        END

        UPDATE Almacen SET
            EstadoAlmacen = 1,
            DateDelete = NULL
        WHERE CodAlmacen = @CodAlmacen;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar el almacén';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Almacén recuperado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar almacén: ' + ERROR_MESSAGE();
    END CATCH
END;