USE Bascula

GO

CREATE PROC Procs_ELIMINAR_VENTA
	@CodigoVenta INT,
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	IF(@CodigoVenta IS NULL)
	BEGIN
		SET @MENSAJE ='El codigo es un campo obligatorio';
		RETURN;
	END

	BEGIN TRANSACTION;
	------------------BUSQUEDA DEL CLIENTE
	DECLARE @Existencia_Venta NVARCHAR(15);
	SET @Existencia_Venta = (SELECT EstadoVenta FROM Venta WITH(UPDLOCK,ROWLOCK) WHERE CodVenta = @CodigoVenta);

	-----VER SI EXISTE LA VENTA
	IF(@Existencia_Venta IS NULL)
	BEGIN
		ROLLBACK TRANSACTION;
		SET @MENSAJE ='E l codigo de la venta no existe en el sistema';
		RETURN;
	END

	IF(@Existencia_Venta = 'cancelada')
	BEGIN
		ROLLBACK TRANSACTION;
		SET @MENSAJE ='La venta ya se encuentra cancelada';
		RETURN;
	END

	UPDATE Venta SET
		EstadoVenta = 'cancelada'
	WHERE CodVenta = @CodigoVenta

	IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al cancelar la venta';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'La venta se cancelo correctamente';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

			SET @MENSAJE = 'Error al cancelar  la venta: ' +ERROR_MESSAGE();
	END CATCH
END