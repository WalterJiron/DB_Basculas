USE Bascula;

GO

-- QUEDA ANULADA

CREATE PROC CreateVentasC
----Venta-----
	@CodCliente INT,
    @TotalVenta DECIMAL(18,4),
	@CodUser UNIQUEIDENTIFIER,
    @Comentario NVARCHAR(300),
    @EstadoVenta NVARCHAR(15),

-----Detalle de Venta
    @CodAlmacen INT,
    @CodProd INT,
    @CodServ INT,
    @Cantidad INT,
    @PrecioUnitario DECIMAL(18,4),

----Pago--
	@CodMetodoPagoC INT,
	@MontoPagoC DECIMAL(18,4),
	@EstadoPagoC NVARCHAR(15),

	@Mensaje  NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @CodPago AS INT,@CodV AS INT;

		BEGIN TRANSACTION;

		EXEC Procs_INSERTARVENTA
			@CodCliente = @CodCliente,
			@TotalVenta = @TotalVenta,
			@CodUser = @CodUser,
			@Comentario = @Comentario,
			@EstadoVenta  = @EstadoVenta,
			@Mensaje = @Mensaje OUTPUT,
			@CodVenta = @CodV OUTPUT;

		IF @CodV IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='Error al registrar la venta: ' + @Mensaje;
			RETURN;
		END

		EXEC Procs_Insertar_DetalleVenta
			@CodVenta = @CodV,
			@CodAlmacen = @CodAlmacen,
			@CodProd = @CodProd,
			@CodServ = @CodServ,
			@Cantidad = @Cantidad,
			@PrecioUnitario = @PrecioUnitario,
			@MENSAJE = @Mensaje OUTPUT;


		IF @Mensaje NOT LIKE '%exitosamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='Error al insertar el detalle de la venta: '+ @Mensaje;
			RETURN;
		END

		EXEC ProcCreatePago
			@CodMetodoPago = @CodMetodoPagoC,
			@MontoPago = @MontoPagoC,
			@IdUser = @CodUser,
			@EstadoPago = @EstadoPagoC,
			@Mensaje = @Mensaje OUTPUT,
			@CodPago = @CodPago OUTPUT;
		
		IF @CodPago IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error al registrar el pago: ' + @Mensaje;
			RETURN;
		END

		EXEC Proc_Inserccion_Pago_Venta
			    @CodPago = @CodPago,
				@CodVenta = @CodV,
				@MENSAJE = @Mensaje OUTPUT;

		IF @Mensaje NOT LIKE '%exitosamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='Error al registrar el pago de la venta: '+ @Mensaje;
			RETURN;
		END

		IF @@ROWCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='Error al ingresar los datos';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje ='Venta registrada exitosamente';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @Mensaje = 'Error al registrar el proceso completo (catch): ' + ERROR_MESSAGE();
	END CATCH
END