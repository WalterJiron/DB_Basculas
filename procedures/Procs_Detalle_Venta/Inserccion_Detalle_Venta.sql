USE Bascula

GO

CREATE PROCEDURE Procs_Insertar_DetalleVenta
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

        -- Validar venta
        DECLARE @ExisteVenta BIT;
        SET @ExisteVenta = (SELECT 1 FROM Venta WITH(UPDLOCK,ROWLOCK) WHERE CodVenta = @CodVenta);

        IF (@ExisteVenta IS NULL)
        BEGIN
            SET @MENSAJE = 'La venta especificada no existe';
            RETURN;
        END

        -- Validar almacén
        DECLARE @ExisteAlmacen BIT;
        SET @ExisteAlmacen = (SELECT EstadoAlmacen FROM Almacen WITH(UPDLOCK,ROWLOCK) WHERE CodAlmacen = @CodAlmacen);

        IF (@ExisteAlmacen IS NULL)
        BEGIN
            SET @MENSAJE = 'El almacen especificado no existe';
            RETURN;
        END

        IF(@ExisteAlmacen = 0)
        BEGIN
            SET @MENSAJE = 'El almacen especificado se encuentra inactivo';
            RETURN;
        END

        -- Validar producto solo si se envió
        IF @CodProd IS NOT NULL
        BEGIN
            DECLARE @ExisteProd BIT, @StockActual INT;
            SElECT @ExisteProd = EstadoProd,
				   @StockActual = Stock
			FROM Producto WITH(UPDLOCK,ROWLOCK)
			WHERE CodProd = @CodProd;

            IF (@ExisteProd IS NULL)
            BEGIN
                SET @MENSAJE = 'El producto especificado no existe';
                RETURN;
            END

            IF (@ExisteProd = 0)
            BEGIN
                SET @MENSAJE = 'El producto está inactivo';
                RETURN;
            END

			IF @StockActual < @Cantidad
			BEGIN
				SET @Mensaje = 'Stock del producto cód.('+ TRY_CONVERT(nvarchar(10),@CodProd) +') insuficiente para realizar la venta.';
				RETURN;
			END
        END

        -- Validar servicio solo si se envio
        IF (@CodServ IS NOT NULL)
        BEGIN
            DECLARE @ExisteServ BIT;
            SET @ExisteServ = (SELECT EstadoServ FROM Servicio WITH(UPDLOCK,ROWLOCK) WHERE CodServ = @CodServ);

            IF (@ExisteServ IS NULL)
            BEGIN
                SET @MENSAJE = 'El servicio especificado no existe';
                RETURN;
            END

            IF(@ExisteServ = 0)
            BEGIN
                SET @MENSAJE ='El servicio especificado se encuentra inactivo';
                RETURN;
            END
        END

        -- Insercion del detalle
        INSERT INTO DetalleVenta (
            CodVenta,
            CodAlmacen,
            CodProd,
            CodServ,
            Cantidad,
            PrecioUnitario
        )
        VALUES (
            @CodVenta,
            @CodAlmacen,
            @CodProd,
            @CodServ,
            @Cantidad,
            @PrecioUnitario
        );

        SET @MENSAJE = 'Detalle de venta registrado exitosamente';

    END TRY
    BEGIN CATCH
        SET @MENSAJE = 'Error al insertar detalle de venta: ' + ERROR_MESSAGE();
    END CATCH
END