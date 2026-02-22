USE Bascula
GO

CREATE PROCEDURE ProcUpdateTaller
	@CodTaller INT,
	@NombreTaller NVARCHAR(50),
	@DescripTaller NVARCHAR(MAX),
	@CodCliente INT,
	@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		
		IF @CodTaller is NULL OR @NombreTaller IS NULL OR @DescripTaller IS NULL OR @CodCliente IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Todos los campos son obligatorios.';
			RETURN;
		END

		IF (LEN(TRIM(@NombreTaller)) < 3 OR LEN(TRIM(@NombreTaller)) > 50)
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del de la reparación en taller tiene que tener de 3 a 50 caracteres.';
			RETURN;
		END

		IF (LEN(TRIM(@DescripTaller)) < 5)
		BEGIN
			SET @Mensaje = 'ERROR: La descripción tiene que tener mínimo 5 caracteres.';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @exist_Taller BIT = (SELECT EstadoTaller FROM Taller WITH (UPDLOCK, ROWLOCK)
							       WHERE CodTaller = @CodTaller);

		IF @exist_Taller IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Reparación en taller del código ('+ TRY_CONVERT(varchar(10),@CodTaller) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_Taller = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La báscula en el taller con el código ('+ TRY_CONVERT(varchar(10),@CodTaller) +') está marcada como "ya reparada".';
			RETURN;
		END

		DECLARE @exist_Cliente BIT = (SELECT EstadoCL FROM Cliente WITH (UPDLOCK, ROWLOCK)
							       WHERE CodCliente = @CodCliente);

		IF @exist_Cliente IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Cliente ('+ TRY_CONVERT(varchar(10),@CodCliente) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_Cliente = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El cliente del código ('+ TRY_CONVERT(varchar(10),@CodCliente) +') está inactivo.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM Taller WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreTaller = @NombreTaller
				   AND CodTaller <> @CodTaller
				   AND EstadoTaller = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Ya existe otro taller activo con el nombre "'+ @NombreTaller +'".';
			RETURN;
		END

		UPDATE Taller
		SET NombreTaller = (lower(TRIM(@NombreTaller))),
			DescripTaller = (lower(TRIM(@DescripTaller))),
			CodCliente = @CodCliente,
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodTaller = @CodTaller;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar la reparación en taller.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Reparación en taller actualizada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @Mensaje = 'Error al actualizar la reparación en taller: ' + ERROR_MESSAGE();
	END CATCH
END