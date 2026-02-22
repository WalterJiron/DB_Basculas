USE Bascula

GO

CREATE PROC ProcInsertAlmacen
    @NombreAlmacen NVARCHAR(50),
    @DescripAlmacen NVARCHAR(250),
    @Direccion NVARCHAR(250),
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @NombreAlmacen IS NULL OR @Direccion IS NULL
        BEGIN
            SET @Mensaje = 'Nombre y dirección son campos obligatorios';
            RETURN;
        END

        -- Validaciones de longitud
        IF LEN(TRIM(@NombreAlmacen)) < 3 OR LEN(TRIM(@NombreAlmacen)) > 50
        BEGIN
            SET @Mensaje = 'El nombre del almacén debe tener entre 3 y 50 caracteres';
            RETURN;
        END

        IF LEN(TRIM(@Direccion)) < 10 OR LEN(TRIM(@Direccion)) > 250
        BEGIN
            SET @Mensaje = 'La dirección debe tener entre 10 y 250 caracteres';
            RETURN;
        END

        IF @DescripAlmacen IS NOT NULL AND LEN(TRIM(@DescripAlmacen)) > 250
        BEGIN
            SET @Mensaje = 'La descripción no puede exceder los 250 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 
            FROM Almacen WITH (UPDLOCK)
            WHERE NombreAlmacen = TRIM(@NombreAlmacen)
                AND EstadoAlmacen = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe un almacén activo con ese nombre';
            RETURN;
        END

        INSERT INTO Almacen ( NombreAlmacen, DescripAlmacen, Direccion )
        VALUES (
            TRIM(@NombreAlmacen),
            TRIM(@DescripAlmacen),
            TRIM(@Direccion)
        );

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error al insertar el almacén';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Almacén registrado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al registrar almacén: ' + ERROR_MESSAGE();
    END CATCH
END;