USE Bascula

GO

CREATE PROC Procs_Update_Venta
    @CodVenta INT,
    @CodCliente INT,
    @TotalVenta DECIMAL(18,4),
    @IdUser UNIQUEIDENTIFIER,
    @Comentario NVARCHAR(300),
    @EstadoVenta NVARCHAR(15),
    @MENSAJE NVARCHAR(150) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF (@CodVenta IS NULL OR @CodCliente IS NULL OR
            @TotalVenta IS NULL OR @IdUser IS NULL)
        BEGIN
            SET @MENSAJE = 'Todos los campos obligatorios deben estar completos';
            RETURN;
        END

        IF @TotalVenta <= 0
        BEGIN
            SET @MENSAJE = 'El total de la venta debe ser mayor que cero';
            RETURN;
        END

        IF LEN(@Comentario) > 300
        BEGIN
            SET @MENSAJE = 'El comentario no puede exceder los 300 caracteres';
            RETURN;
        END

		DECLARE @EstadoVentaClean NVARCHAR(15) = LOWER(LTRIM(RTRIM(@EstadoVenta)));

		IF @EstadoVentaClean NOT IN ('registrada', 'completada', 'cancelada')
		BEGIN
			SET @MENSAJE = 'El estado de la venta debe ser registrada, Completada o Cancelada.';
			RETURN;
		END

        BEGIN TRANSACTION;

--------busqueda del cliente
		DECLARE @Existe_Cliente BIT;
		SET @Existe_Cliente = (SELECT EstadoCL FROM Cliente WITH (UPDLOCK,ROWLOCK) WHERE CodCliente = @CodCliente);

		IF(@Existe_Cliente IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='El cliente no existe';
			RETURN;
		END

		IF(@Existe_Cliente = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='El cliente especificado se encuentra inactivo';
			RETURN;
		END

		DECLARE @Existe_User BIT;
		SET @Existe_User = (SELECT EstadoUser FROM Users WITH (UPDLOCK,ROWLOCK) WHERE CodigoUser = @IdUser);

		IF(@Existe_User IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='El usuario no existe';
			RETURN;
		END

		IF(@Existe_User = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje ='El usuario especificado se encuentra inactivo';
			RETURN;
		END

		-- Validar existencia de venta
		DECLARE @Existe_Venta BIT;
		SET @Existe_Venta = (SELECT 1 FROM Venta WHERE CodVenta = @CodVenta);

		IF (@Existe_Venta IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'La venta no existe';
			RETURN;
		END

		DECLARE @EstadoVentaActual NVARCHAR(15);
		SET @EstadoVentaActual = (SELECT EstadoVenta FROM Venta WHERE CodVenta = @CodVenta);

		IF LOWER(TRIM(@EstadoVentaActual)) = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'No se puede actualizar una venta cancelada';
			RETURN;
		END

        UPDATE Venta
        SET CodCliente = @CodCliente,
            TotalVenta = @TotalVenta,
            IdUser = @IdUser,
            Comentario = @Comentario,
            EstadoVenta = @EstadoVenta,
            FechaVenta = SYSDATETIMEOFFSET()
        WHERE CodVenta = @CodVenta;

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo actualizar la venta';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Venta actualizada exitosamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al actualizar venta: ' + ERROR_MESSAGE();
    END CATCH
END
