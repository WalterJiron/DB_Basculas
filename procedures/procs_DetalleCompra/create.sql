USE Bascula
GO

CREATE PROCEDURE ProcCreateDetalleCompra
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
		IF @CodCompra IS NULL OR @CodAlmacen IS NULL OR @CodProd IS NULL OR @Cantidad IS NULL OR @PrecioUnit IS NULL
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

		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
							       WHERE CodCompra = @CodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Compra = 'cancelada'
		BEGIN
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') fue cancelada, no se puede registrar el detalle.';
			RETURN;
		END

		DECLARE @exist_Almacen BIT = (SELECT EstadoAlmacen FROM Almacen WITH (UPDLOCK, ROWLOCK)
							       WHERE CodAlmacen = @CodAlmacen);

		IF @exist_Almacen IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código Almacen ('+ TRY_CONVERT(nvarchar(10),@CodAlmacen) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Almacen = 0
		BEGIN
			SET @Mensaje = 'ERROR: El almacen del código ('+ TRY_CONVERT(nvarchar(10),@CodAlmacen) +') se encuentra desactivado.';
			RETURN;
		END

		DECLARE @exist_Prod BIT = (SELECT EstadoProd FROM Producto WITH (UPDLOCK, ROWLOCK)
							       WHERE CodProd = @CodProd);

		IF @exist_Prod IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Producto ('+ TRY_CONVERT(nvarchar(10),@CodProd) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Prod = 0
		BEGIN
			SET @Mensaje = 'ERROR: El producto del código ('+ TRY_CONVERT(nvarchar(10),@CodProd) +') se encuentra desactivado.';
			RETURN;
		END

		/*IF EXISTS (SELECT 1 FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
				   WHERE CodCompra = @CodCompra
				   AND EstadoDetCompra = 1)
		BEGIN
			SET @Mensaje = 'ERROR: Ya existe otro registro de detalles con la compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +').';
			RETURN;
		END*/
		-- Para tener varios detalles y con ello varios productos

		INSERT INTO DetalleCompra(CodCompra, CodAlmacen, CodProd, Cantidad, PrecioUnitario)
		VALUES (@CodCompra, @CodAlmacen, @CodProd, @Cantidad, @PrecioUnit);

		SET @Mensaje = 'Detalle de compra registrado correctamente.';
	END TRY
	BEGIN CATCH
		SET @Mensaje = 'Error al registrar detalle de compra: ' + ERROR_MESSAGE();
	END CATCH
END