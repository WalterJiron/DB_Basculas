USE Bascula

GO

Create PROCEDURE Procs_INSERTARVENTA
	@CodCliente INT,
    @TotalVenta DECIMAL(18,4),
	@CodUser UNIQUEIDENTIFIER,
    @Comentario NVARCHAR(300),
    @EstadoVenta NVARCHAR(15),
    @Mensaje NVARCHAR(100) OUTPUT,
	@CodVenta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
    -- Validaciones
	IF @CodCliente IS NULL OR  @CodUser IS NULL OR  @TotalVenta IS NULL OR @EstadoVenta IS NULL
	BEGIN
		SET @Mensaje ='Los campos obligatorios no pueden ser nulos';
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

    -- Insercion

		DECLARE @EstadoVentaClean NVARCHAR(15) = LOWER(LTRIM(RTRIM(@EstadoVenta)));

		IF @EstadoVentaClean NOT IN ('registrada', 'completada', 'cancelada')
		BEGIN
			SET @Mensaje = 'El estado de la venta debe ser registrada, Completada o Cancelada.';
			RETURN;
		END

		--------busqueda del cliente
		DECLARE @Existe_Cliente BIT;
		SET @Existe_Cliente = (SELECT EstadoCL FROM Cliente WITH (UPDLOCK,ROWLOCK) WHERE CodCliente = @CodCliente);

		IF(@Existe_Cliente IS NULL)
		BEGIN
			SET @Mensaje ='El cliente no existe';
			RETURN;
		END

		IF(@Existe_Cliente = 0)
		BEGIN
			SET @Mensaje ='El cliente especificado se encuentra inactivo';
			RETURN;
		END


		DECLARE @Existe_User BIT;
		SET @Existe_User = (SELECT EstadoUser FROM Users WITH (UPDLOCK,ROWLOCK) WHERE CodigoUser = @CodUser);

		IF(@Existe_User IS NULL)
		BEGIN
			SET @Mensaje ='El usuario no existe';
			RETURN;
		END

		IF(@Existe_User = 0)
		BEGIN
			SET @Mensaje ='El usuario especificado se encuentra inactivo';
			RETURN;
		END

       INSERT INTO Venta (
            CodCliente,
            TotalVenta,
            IdUser,
            Comentario,
            EstadoVenta
        )
        VALUES (
            @CodCliente,
            @TotalVenta,
            @CodUser,
            @Comentario,
            @EstadoVentaClean
        );


      -- Capturar ID recién insertado
        SET @CodVenta = CAST(SCOPE_IDENTITY() AS INT);

        SET @MENSAJE = 'Detalle de venta registrado exitosamente';


    END TRY
    BEGIN CATCH

        SET @MENSAJE = 'Error al insertar detalle de venta: ' + ERROR_MESSAGE();
    END CATCH
END

