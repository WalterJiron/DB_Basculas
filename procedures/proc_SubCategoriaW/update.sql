USE Bascula;

GO

CREATE PROC ProcUpdateSubCategoria
    @CodSubCat INT,
    @NombreSubCat NVARCHAR(50),
    @DescripSubCat NVARCHAR(MAX),
    @CodCat INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @CodSubCat IS NULL OR @NombreSubCat IS NULL OR @DescripSubCat IS NULL OR @CodCat IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        -- Validaciones de longitud
        IF LEN(TRIM(@NombreSubCat)) < 3 OR LEN(TRIM(@NombreSubCat)) > 50
        BEGIN
            SET @Mensaje = 'El nombre de subcategoría debe tener entre 3 y 50 caracteres';
            RETURN;
        END

        IF LEN(TRIM(@DescripSubCat)) < 10
        BEGIN
            SET @Mensaje = 'La descripción debe tener al menos 10 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        
        SELECT @EstadoActual = EstadoSubCat
        FROM SubCategoria WITH (UPDLOCK, ROWLOCK)
        WHERE CodSubCat = @CodSubCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría se encuentra inactiva';
            RETURN;
        END

        -- Verificar que la categoria padre exista y este activa
        IF NOT EXISTS (
            SELECT 1 FROM Categoria WITH (UPDLOCK)
            WHERE CodCat = @CodCat AND EstadoCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría especificada no existe o está inactiva';
            RETURN;
        END

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 FROM SubCategoria WITH (UPDLOCK)
            WHERE NombreSubCat = TRIM(@NombreSubCat)
              AND CodSubCat <> @CodSubCat
              AND EstadoSubCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe una subcategoría activa con ese nombre';
            RETURN;
        END

        UPDATE SubCategoria SET
            NombreSubCat = TRIM(@NombreSubCat),
            DescripSubCat = TRIM(@DescripSubCat),
            CodCat = @CodCat,
            DateUpdate = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
        WHERE CodSubCat = @CodSubCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar la subcategoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Subcategoría actualizada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al actualizar subcategoría: ' + ERROR_MESSAGE();
    END CATCH
END;
GO