USE Bascula;

GO

CREATE PROC CreateProductsC
    @nombreProd NVARCHAR(50),
    @descripProc NVARCHAR(MAX),
    @codigoSubCat INT,
    @stockProd INT,
    @stockMinimoD INT,
    @precioUnitarioD DECIMAL(18,4),
    @precioVentaD DECIMAL(18,4),
    @message NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @mensaje AS NVARCHAR(100), @codigo AS INT; 
        
        BEGIN TRANSACTION;
        
        EXEC ProcInsertProducto
            @NombreProd = @nombreProd,
            @DescripProd = @descripProc,
            @CodSubCat = @codigoSubCat,
            @Stock = @stockProd,
            @Mensaje = @mensaje OUTPUT,
            @CodProd = @codigo OUTPUT;
        
        IF @codigo IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT @mensaje;
            SET @message = 'Error al ingresar el producto: ' + @mensaje;
            RETURN;
        END
        
        EXEC ProcInsertDetalleProducto
            @CodProd = @codigo,
            @StockMinimo = @stockMinimoD,
            @PrecioUnitario = @precioUnitarioD,
            @PrecioVenta = @precioVentaD,
            @Mensaje = @mensaje OUTPUT;

        IF @mensaje NOT LIKE '%correctamente%'
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT @mensaje;
            SET @message = 'Error al ingresar el detalle del producto: ' + @message;
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @message = 'Producto y detalle registrados correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @message = 'Error al registrar producto (catch): ' + ERROR_MESSAGE();
    END CATCH
END