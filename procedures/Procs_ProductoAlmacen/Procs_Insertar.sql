USE Bascula

GO

CREATE PROCEDURE Procs_Insertar_ProductoAlmacen
    @CodAlmacen INT,
    @CodProd INT,
    @StockActual INT,
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @CodAlmacen IS NULL OR @CodProd IS NULL OR @StockActual IS NULL
        BEGIN
            SET @MENSAJE = 'Todos los campos obligatorios deben estar completos.';
            RETURN;
        END

        IF @StockActual <= 0
        BEGIN
            SET @MENSAJE = 'El stock actual no puede ser negativo.';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Validar existencia del almacén activo
		DECLARE @EXISTENCIA_ALMACEN BIT;
		SET @EXISTENCIA_ALMACEN = (SELECT EstadoAlmacen FROM Almacen WHERE CodAlmacen = @CodAlmacen);

        IF(@EXISTENCIA_ALMACEN IS NULL )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El almacén especificado no existe.';
            RETURN;
        END

		If(@EXISTENCIA_ALMACEN = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El almacen se encuntra inactivo';
			RETURN;
		END

        -- Validar existencia del producto activo
		DECLARE @EXISTENCIA_PRODUCTO BIT;
		SET @EXISTENCIA_PRODUCTO = (SELECT EstadoProd FROM Producto WHERE CodProd = @CodProd);

        IF(@EXISTENCIA_PRODUCTO  IS NULL)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El producto especificado no existe ';
            RETURN;
        END

		IF(@EXISTENCIA_PRODUCTO = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El producto especificado se encuentra inactivo';
		END

        -- Obtener stock total del producto y stock ya distribuido 
        DECLARE @StockProducto INT;
        DECLARE @StockDistribuido INT;

        SELECT 
            @StockProducto = p.Stock,
            @StockDistribuido = ISNULL(SUM(pa.StockActual), 0)
        FROM Producto p
        LEFT JOIN ProductoAlmacen pa
            ON p.CodProd = pa.CodProd
            AND pa.EstadoAlmacenProd = 1
        WHERE p.CodProd = @CodProd AND p.EstadoProd = 1
        GROUP BY p.Stock;

        -- Validar que no se exceda el stock 
        IF @StockDistribuido + @StockActual > @StockProducto
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se puede agregar el producto: el stock distribuido supera el stock disponible del producto.';
            RETURN;
        END

		-- Validar que no exista ya un registro activo del producto en ese almacén
		IF EXISTS (SELECT 1 FROM ProductoAlmacen WITH (UPDLOCK, ROWLOCK) WHERE CodAlmacen = @CodAlmacen 
		  AND CodProd = @CodProd 
		  AND EstadoAlmacenProd = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Ya existe una asignación activa del producto en el almacén.';
			RETURN;
		END

        -- Insertar 
        INSERT INTO ProductoAlmacen (
            CodAlmacen,
            CodProd,
            StockActual
        )
        VALUES (
            @CodAlmacen,
            @CodProd,
            @StockActual
        );

		IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'Error al insertar el producto en el almacen.';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Producto insertado en el almacén exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al insertar producto en almacén: ' + ERROR_MESSAGE();
    END CATCH
END


