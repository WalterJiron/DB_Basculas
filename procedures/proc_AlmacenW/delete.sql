USE Bascula;

GO

CREATE PROC ProcDeleteAlmacen
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
        
        SELECT @EstadoActual = EstadoAlmacen
        FROM Almacen WITH (UPDLOCK, HOLDLOCK)
        WHERE CodAlmacen = @CodAlmacen;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El almacén no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El almacén ya se encuentra eliminado';
            RETURN;
        END

        -- Verificar si hay productos asociados al almacen
        IF EXISTS (
            SELECT 1 FROM Producto AS P
            JOIN ProductoAlmacen AS PA 
            ON PA.CodAlmacen = @CodAlmacen 
            WHERE P.EstadoProd = 1  
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede eliminar, existen productos activos en este almacén';
            RETURN;
        END

        -- Actualizar estado
        UPDATE Almacen SET
            EstadoAlmacen = 0,
            DateDelete = SYSDATETIMEOFFSET()
        WHERE CodAlmacen = @CodAlmacen;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar el almacén';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Almacén desactivado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar almacén: ' + ERROR_MESSAGE();
    END CATCH
END;