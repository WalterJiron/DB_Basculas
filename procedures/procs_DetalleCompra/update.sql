USE Bascula
GO

CREATE PROCEDURE ProcUpdateDetalleCompra
@CodDetCompra INT,
@CodCompra INT,
@CodAlmacen INT,
@CodProd INT,
@Cantidad INT,
@PrecioUnit DECIMAL(18,4),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF @CodDetCompra IS NULL OR @CodCompra IS NULL OR @CodAlmacen IS NULL OR @CodProd IS NULL OR @Cantidad IS NULL OR @PrecioUnit IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Todos los campos son obligatorios';
			RETURN;
		END

		IF @Cantidad <= 0
		BEGIN
			SET @Mensaje = 'ERROR: La cantidad de productos debe ser mayor que 0.';
			RETURN;
		END

		IF @PrecioUnit <= 0
		BEGIN
			SET @Mensaje = 'ERROR: El precio unitario de compra debe ser mayor que 0.';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @exist_DetCompra BIT = (SELECT EstadoDetCompra FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
							       WHERE CodDetCompra = @CodDetCompra);

		IF @exist_DetCompra IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Detalle de compra ('+ TRY_CONVERT(nvarchar(10),@CodDetCompra) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_DetCompra = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El detalle de compra del código ('+ TRY_CONVERT(nvarchar(10),@CodDetCompra) +') se encuentra inactivo.';
			RETURN;
		END


		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
							       WHERE CodCompra = @CodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Compra = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') fue cancelada, no se puede registrar su detalle.';
			RETURN;
		END


		DECLARE @exist_Almacen BIT = (SELECT EstadoAlmacen FROM Almacen WITH (UPDLOCK, ROWLOCK)
							       WHERE CodAlmacen = @CodAlmacen);

		IF @exist_Almacen IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Almacen ('+ TRY_CONVERT(nvarchar(10),@CodAlmacen) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_Almacen = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El almacen del código ('+ TRY_CONVERT(nvarchar(10),@CodAlmacen) +') se encuentra desactivado.';
			RETURN;
		END

		DECLARE @exist_Prod BIT = (SELECT EstadoProd FROM Producto WITH (UPDLOCK, ROWLOCK)
							       WHERE CodProd = @CodProd);

		IF @exist_Prod IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Producto ('+ TRY_CONVERT(nvarchar(10),@CodProd) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Prod = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El producto del código ('+ TRY_CONVERT(nvarchar(10),@CodProd) +') se encuentra desactivado.';
			RETURN;
		END

		UPDATE DetalleCompra
		SET CodCompra = @CodCompra,
			CodAlmacen = @CodAlmacen,
			CodProd = @CodProd,
			Cantidad = @Cantidad,
			PrecioUnitario = @PrecioUnit,
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodDetCompra = @CodDetCompra;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar detalle de compra.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Detalle de compra actualizado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar detalle de compra: ' + ERROR_MESSAGE();
	END CATCH
END