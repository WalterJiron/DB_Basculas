USE Bascula

GO

CREATE PROCEDURE Procs_Actualizar_ProductosAlmacen
    @CodAlmacen INT,
    @CodProd INT,
    @NuevoStock INT,
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @CodAlmacen IS NULL OR @CodProd IS NULL OR @NuevoStock IS NULL
        BEGIN
            SET @MENSAJE = 'Los campos Almacen, Producto y Stock son obligatorios.';
            RETURN;
        END

        IF @NuevoStock <= 0
        BEGIN
            SET @MENSAJE = 'El stock no puede ser negativo.';
            RETURN;
        END

		BEGIN TRANSACTION;
		        -- Verificar existencia de almacen
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

        -- Verificar que no exista la combinacion (CodAlmacen, CodProd)
        IF NOT EXISTS (SELECT 1 FROM ProductoAlmacen WHERE CodAlmacen = @CodAlmacen AND CodProd = @CodProd)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El producto no existe en el almacen especificado.';
            RETURN;
        END

        -- Obtener stock total del producto y stock distribuido (excluyendo este almacén)

		DECLARE @StockProducto INT;
		DECLARE @StockDistribuido INT;

		SELECT @StockProducto = p.Stock,
			   @StockDistribuido = ISNULL(SUM(pa.StockActual), 0)
		FROM Producto p
		LEFT JOIN ProductoAlmacen pa
			ON p.CodProd = pa.CodProd
			AND pa.EstadoAlmacenProd = 1
			AND pa.CodAlmacen <> @CodAlmacen
		WHERE p.CodProd = @CodProd AND p.EstadoProd = 1
		GROUP BY p.Stock;

		-- Validar que el nuevo total no exceda el stock disponible
		IF @StockDistribuido + @NuevoStock > @StockProducto
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'No se puede actualizar: el nuevo stock supera el stock total disponible del producto.';
			RETURN;
		END


	------actualizar
        UPDATE ProductoAlmacen SET 
            StockActual = @NuevoStock,
            DateUpdate = SYSDATETIMEOFFSET()
        WHERE CodAlmacen = @CodAlmacen AND CodProd = @CodProd;

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo actualizar el registro.';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Registro actualizado correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al actualizar ProductoAlmacen: ' + ERROR_MESSAGE();
    END CATCH
END
