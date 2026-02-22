USE Bascula;

GO

CREATE PROC ProcInsertDetalleProducto
    @CodProd INT,
    @StockMinimo INT,
    @PrecioUnitario DECIMAL(18,4),
    @PrecioVenta DECIMAL(18,4),
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @CodProd IS NULL OR @StockMinimo IS NULL OR @PrecioUnitario IS NULL OR @PrecioVenta IS NULL
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


        -- Verificar que el producto exista y este activo
        IF NOT EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE CodProd = @CodProd AND EstadoProd = 1
        )
        BEGIN
            SET @Mensaje = 'El producto especificado no existe o está inactivo';
            RETURN;
        END

        -- Verificar que no exista ya un detalle activo para este producto
        IF EXISTS (
            SELECT 1 FROM DetalleProducto WITH (UPDLOCK)
            WHERE CodProd = @CodProd AND EstadoDetProd = 1
        )
        BEGIN
            SET @Mensaje = 'Ya existe un detalle activo para este producto';
            RETURN;
        END

        INSERT INTO DetalleProducto (
            CodProd, StockMinimo,
            PrecioUnitario, PrecioVenta
        )
        VALUES (
            @CodProd, @StockMinimo,
            @PrecioUnitario, @PrecioVenta
        );

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            SET @Mensaje = 'Error al insertar el detalle de producto';
            RETURN;
        END

        SET @Mensaje = 'Detalle de producto registrado correctamente';
    END TRY
    BEGIN CATCH
        SET @Mensaje = 'Error al registrar detalle de producto: ' + ERROR_MESSAGE();
    END CATCH
END;