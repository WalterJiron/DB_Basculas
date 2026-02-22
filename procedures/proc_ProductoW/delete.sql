USE Bascula;

GO

CREATE PROC ProcDeleteProducto
    @CodProd INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de producto
        IF @CodProd IS NULL
        BEGIN
            SET @Mensaje = 'El código de producto es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        
        SELECT @EstadoActual = EstadoProd
        FROM Producto WITH (UPDLOCK, HOLDLOCK)
        WHERE CodProd = @CodProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto ya se encuentra eliminado';
            RETURN;
        END

        -- Verificar si hay stock disponible
        DECLARE @StockActual INT;
        SELECT @StockActual = Stock FROM Producto WHERE CodProd = @CodProd;
        
        IF @StockActual > 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede eliminar, el producto tiene stock disponible';
            RETURN;
        END

        -- Actualizar estado
        UPDATE Producto SET
            EstadoProd = 0,
            DateDelete = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
        WHERE CodProd = @CodProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar el producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Producto desactivado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar producto: ' + ERROR_MESSAGE();
    END CATCH
END;