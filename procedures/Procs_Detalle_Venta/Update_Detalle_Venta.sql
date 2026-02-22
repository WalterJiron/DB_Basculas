USE Bascula

GO

CREATE PROCEDURE Procs_Actualizar_Detalle_Venta
    @CodDetVenta INT,
    @CodVenta INT,
    @CodAlmacen INT,
    @CodProd INT,
    @CodServ INT,
    @Cantidad INT,
    @PrecioUnitario DECIMAL(18,4),
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar campos obligatorios
        IF @CodVenta IS NULL OR @CodAlmacen IS NULL OR @Cantidad IS NULL OR @PrecioUnitario IS NULL
        BEGIN
            SET @MENSAJE = 'Los campos Codigo de Venta, Codigo de almacen, Cantidad y Precio Unitario son obligatorios.';
            RETURN;
        END

        IF (@Cantidad <= 0 OR @PrecioUnitario <= 0)
        BEGIN
            SET @MENSAJE = 'La cantidad y el precio unitario deben ser mayor que cero';
            RETURN;
        END

        IF @CodProd IS NULL AND @CodServ IS NULL
        BEGIN
            SET @MENSAJE = 'Debe proporcionar al menos el Codigo de producto o el codigo del servicio.';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Validar venta
        IF NOT EXISTS (SELECT 1 FROM Venta WITH(UPDLOCK,ROWLOCK) WHERE CodVenta = @CodVenta)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'La venta especificada no existe';
            RETURN;
        END

        -- Validar almacén
        DECLARE @EstadoAlmacen BIT;
        SET @EstadoAlmacen = (SELECT EstadoAlmacen FROM Almacen WITH(UPDLOCK,ROWLOCK) WHERE CodAlmacen = @CodAlmacen);

        IF (@EstadoAlmacen IS NULL)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El almacen especificado no existe';
            RETURN;
        END

        IF (@EstadoAlmacen = 0)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El almacen especificado se encuentra inactivo';
            RETURN;
        END

        -- Validar producto solo si se envió
        IF @CodProd IS NOT NULL
        BEGIN
            DECLARE @EstadoProd BIT, @StockActual INT;
            SElECT @EstadoProd = EstadoProd,
				   @StockActual = Stock
			FROM Producto WITH(UPDLOCK,ROWLOCK)
			WHERE CodProd = @CodProd;

            IF (@EstadoProd IS NULL)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @MENSAJE = 'El producto especificado no existe';
                RETURN;
            END

            IF (@EstadoProd = 0)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @MENSAJE = 'El producto está inactivo';
                RETURN;
            END

			IF @StockActual < @Cantidad
			BEGIN
				ROLLBACK TRANSACTION;
				SET @Mensaje = 'Stock del producto cód.('+ TRY_CONVERT(nvarchar(10),@CodProd) +') insuficiente para realizar la venta.';
				RETURN;
			END
        END

        -- Validar servicio solo si se envió
        IF @CodServ IS NOT NULL
        BEGIN
            DECLARE @EstadoServ BIT;
            SET @EstadoServ = (SELECT EstadoServ FROM Servicio WITH(UPDLOCK,ROWLOCK) WHERE CodServ = @CodServ);

            IF (@EstadoServ IS NULL)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @MENSAJE = 'El servicio especificado no existe';
                RETURN;
            END

            IF (@EstadoServ = 0)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @MENSAJE = 'El servicio especificado se encuentra inactivo';
                RETURN;
            END
        END
        -- Realizar UPDATE
        UPDATE DetalleVenta SET
            CodVenta = @CodVenta,
            CodAlmacen = @CodAlmacen,
            CodProd = @CodProd,
            CodServ = @CodServ,
            Cantidad = @Cantidad,
            PrecioUnitario = @PrecioUnitario,
            DateUpdate = SYSDATETIMEOFFSET()
        WHERE CodDetVenta = @CodDetVenta;

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo actualizar el detalle de venta';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Detalle de venta actualizada exitosamente';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al actualizar detalle de venta: ' + ERROR_MESSAGE();
    END CATCH
END
		