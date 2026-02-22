USE Bascula;

GO

CREATE PROC ProcInsertCategoria
    @NombreCat NVARCHAR(50),
    @DescripCat NVARCHAR(MAX),
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @NombreCat IS NULL OR @DescripCat IS NULL
        BEGIN
            SET @Mensaje = 'Nombre y descripción son campos obligatorios';
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
            SET @Mensaje = 'La descripción debe tener al menos 5 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 FROM Categoria WITH (UPDLOCK)
            WHERE NombreCat = TRIM(@NombreCat)
              AND EstadoCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe una categoría activa con ese nombre';
            RETURN;
        END

        -- Insertar la nueva categoria
        INSERT INTO Categoria (
            NombreCat,
            DescripCat
        )
        VALUES (
            TRIM(@NombreCat),
            TRIM(@DescripCat)
        );

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error al insertar la categoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Categoría registrada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al registrar categoría: ' + ERROR_MESSAGE();
    END CATCH
END;