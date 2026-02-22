USE Bascula;

GO

CREATE PROC ProcInsertSubCategoria
    @NombreSubCat NVARCHAR(50),
    @DescripSubCat NVARCHAR(MAX),
    @CodCat INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @NombreSubCat IS NULL OR @DescripSubCat IS NULL OR @CodCat IS NULL
        BEGIN
            SET @Mensaje = 'Nombre, descripción y categoría son campos obligatorios';
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
              AND EstadoSubCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe una subcategoría activa con ese nombre';
            RETURN;
        END

        INSERT INTO SubCategoria ( NombreSubCat, DescripSubCat, CodCat )
        VALUES (
            TRIM(@NombreSubCat),
            TRIM(@DescripSubCat),
            @CodCat
        );

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error al insertar la subcategoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Subcategoría registrada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al registrar subcategoría: ' + ERROR_MESSAGE();
    END CATCH
END;