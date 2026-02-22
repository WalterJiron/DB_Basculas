USE Bascula;

GO

-- QUEDA ANULADA
CREATE PROC CreateCompraPagoC
	-- Compra
	@CodProvC INT,
	@TotalCompraC DECIMAL(18,4),
	@IdUserC UNIQUEIDENTIFIER,
	@ComentarioC NVARCHAR(MAX),
	@EstadoCompraC NVARCHAR(15),
	
	-- DetalleCompra
	@CodAlmacenC INT,
	@CodProdC INT,
	@CantidadC INT,
	@PrecioUnitC DECIMAL(18,4),

	-- Pago
	@CodMetodoPagoC INT,
	@MontoPagoC DECIMAL(18,4),
	@EstadoPagoC NVARCHAR(15),

	@MensajeC NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		DECLARE @CodCompraC INT, @CodPagoC INT;
		-- Solo se obtienen hasta que se realiza un Proc para uso en otro Proc siguiente
		
		BEGIN TRANSACTION;
		
		-- Compra
		EXEC ProcCreateCompra
			@CodProv = @CodProvC,
			@TotalCompra = @TotalCompraC,
			@IdUser = @IdUserC,
			@Comentario = @ComentarioC,
			@EstadoCompra = @EstadoCompraC,
			@Mensaje = @MensajeC OUTPUT,
			@CodCompra = @CodCompraC OUTPUT;
		
		IF @CodCompraC IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MensajeC = 'Error al registrar la compra: ' + @MensajeC;
			RETURN;
		END
		
		-- DetalleCompra
		EXEC ProcCreateDetalleCompra
			@CodCompra = @CodCompraC,
			@CodAlmacen = @CodAlmacenC,
			@CodProd = @CodProdC,
			@Cantidad = @CantidadC,
			@PrecioUnit = @PrecioUnitC,
			@Mensaje = @MensajeC OUTPUT;
			
		IF @MensajeC NOT LIKE '%correctamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MensajeC = 'Error al registrar el detalle de la compra: ' + @MensajeC;
			RETURN;
		END

		-- Pago
		EXEC ProcCreatePago
			@CodMetodoPago = @CodMetodoPagoC,
			@MontoPago = @MontoPagoC,
			@IdUser = @IdUserC,
			@EstadoPago = @EstadoPagoC,
			@Mensaje = @MensajeC OUTPUT,
			@CodPago = @CodPagoC OUTPUT;
		
		IF @CodPagoC IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MensajeC = 'Error al registrar el pago: ' + @MensajeC;
			RETURN;
		END
		
		-- PagoCompra
		EXEC ProcCreatePagoCompra
			@CodPago = @CodPagoC,
			@CodCompra = @CodCompraC,
			@Mensaje = @MensajeC OUTPUT;
		
		IF @MensajeC NOT LIKE '%correctamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MensajeC = 'Error al registrar la relaci�n pago-compra: ' + @MensajeC;
			RETURN;
		END

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MensajeC = 'Error al registrar la compra, su detalle, el pago y la relaci�n.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @MensajeC = 'Compra, detalle, pago y relaci�n registrados correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @MensajeC = 'Error al registrar el proceso completo (catch): ' + ERROR_MESSAGE();
	END CATCH
END
GO