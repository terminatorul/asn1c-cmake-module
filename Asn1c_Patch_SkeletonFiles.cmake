# Copy missing ASN1c skeleton files to the working directory

foreach(ASN1_COPY_SKELETON_FILE ${ASN1_COPY_SKELETON_FILES})
    configure_file(
        "${ASN1C_SHARED_INCLUDE_DIR}/${ASN1_COPY_SKELETON_FILE}"
        "${ASN1_WORKING_DIRECTORY}/${ASN1_COPY_SKELETON_FILE}"
        COPYONLY)
endforeach()
