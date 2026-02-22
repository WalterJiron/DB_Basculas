USE Bascula;

GO

CREATE PROC ProcUpdateDetalleProducto
    @CodDetProd INT,
    @StockMinimo INT,
    @PrecioUnitario DECIMAL(18,4),
    @PrecioVenta DECIMAL(18,4),
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @CodDetProd IS NULL OR @StockMinimo IS NULL OR @PrecioUnitario IS NULL OR @PrecioVenta IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        -- Validaciones de valores
        IF @StockMinimo < 0
        BEGIN
            SET @Mensaje = 'El stock mínimo no puede ser negativo';
            RETURN;
        END

        IF @PrecioUnitario <= 0
        BEGIN
            SET @Mensaje = 'El precio unitario debe ser mayor que cero';
            RETURN;
        END

        IF @PrecioVenta <= 0
        BEGIN
            SET @Mensaje = 'El precio de venta debe ser mayor que cero';
            RETURN;
        END

        -- Validar margen de ganancia 
        IF @PrecioVenta < @PrecioUnitario
        BEGIN
            SET @Mensaje = 'El precio de venta no puede ser menor al precio unitario';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @CodProd INT;
        
        SELECT @EstadoActual = EstadoDetProd,
               @CodProd = CodProd
        FROM DetalleProducto WITH (UPDLOCK, ROWLOCK)
        WHERE CodDetProd = @CodDetProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto se encuentra inactivo';
            RETURN;
        END

        -- Verificar que el producto este activo
        IF NOT EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE CodProd = @CodProd AND EstadoProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto asociado está inactivo';
            RETURN;
        END

        UPDATE DetalleProducto SET
            StockMinimo = @StockMinimo,
            PrecioUnitario = @PrecioUnitario,
            PrecioVenta = @PrecioVenta,
            DateUpdate = SYSDATETIMEOFFSET() 
        WHERE CodDetProd = @CodDetProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar el detalle de producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Detalle de producto actualizado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al actualizar detalle de producto: ' + ERROR_MESSAGE();
    END CATCH
END;