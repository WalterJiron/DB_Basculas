USE Bascula;

GO

CREATE PROC ProcUpdateCategoria
    @CodCat INT,
    @NombreCat NVARCHAR(50),
    @DescripCat NVARCHAR(MAX),
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @CodCat IS NULL OR @NombreCat IS NULL OR @DescripCat IS NULL
        BEGIN
            SET @Mensaje = 'Código, nombre y descripción son campos obligatorios';
            RETURN;
        END

        -- Validaciones de longitud
        IF LEN(TRIM(@NombreCat)) < 3 OR LEN(TRIM(@NombreCat)) > 50
        BEGIN
            SET @Mensaje = 'El nombre de categoría debe tener entre 3 y 50 caracteres';
            RETURN;
        END

        IF LEN(TRIM(@DescripCat)) < 5
        BEGIN
            SET @Mensaje = 'La descripción debe tener al menos 10 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        
        SELECT @EstadoActual = EstadoCat
        FROM Categoria WITH (UPDLOCK, ROWLOCK)
        WHERE CodCat = @CodCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría se encuentra inactiva';
            RETURN;
        END

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 FROM Categoria WITH (UPDLOCK)
            WHERE NombreCat = TRIM(@NombreCat) AND CodCat <> @CodCat AND EstadoCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe una categoría activa con ese nombre';
            RETURN;
        END

        -- Actualizar la categoria
        UPDATE Categoria SET
            NombreCat = TRIM(@NombreCat),
            DescripCat = TRIM(@DescripCat),
            DateUpdate = SYSDATETIMEOFFSET() 
        WHERE CodCat = @CodCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar la categoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Categoría actualizada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al actualizar categoría: ' + ERROR_MESSAGE();
    END CATCH
END;
