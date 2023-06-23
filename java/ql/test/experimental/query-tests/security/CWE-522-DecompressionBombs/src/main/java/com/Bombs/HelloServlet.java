package com.Bombs;

import org.apache.commons.compress.archivers.ArchiveException;
import org.apache.commons.compress.compressors.CompressorException;

import static com.Bombs.CommonsCompressHandler.*;
import static com.Bombs.SnappyHandler.*;
import static com.Bombs.Zip4jHandler.*;
import static com.Bombs.ZipHandler.*;

import java.io.*;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

@WebServlet(
    name = "helloServlet",
    urlPatterns = {"/hello-servlet"})
@MultipartConfig()
public class HelloServlet extends HttpServlet {

  public void init() {}

  public void doPost(HttpServletRequest request, HttpServletResponse response)
      throws IOException, ServletException {
    response.setContentType("text/html");
    Part remoteFile = request.getPart("zipFile");
    // Zip
    ZipInputStreamSafe2(remoteFile.getInputStream());
    ZipInputStreamSafe(request.getPart("zipFile").getInputStream());
    ZipInputStreamUnsafe(remoteFile.getInputStream());
    GZipInputStreamUnsafe(request.getPart("zipFile").getInputStream());
    InflaterInputStreamUnsafe(request.getPart("zipFile").getInputStream());

    // Zip4j
    zip4jZipInputStream(remoteFile.getInputStream());
    zip4jZipInputStreamSafe(remoteFile.getInputStream());
    // SnappyZip
    SnappyZipInputStream(remoteFile.getInputStream());
    // apache Commons
    commonsCompressArchiveInputStream2(remoteFile.getInputStream());
    commonsCompressorInputStream(remoteFile.getInputStream());
    try {
      commonsCompressArchiveInputStream(remoteFile.getInputStream());
      commonsCompressArchiveStreamFactory(remoteFile.getInputStream());
    } catch (ArchiveException e) {
      throw new RuntimeException(e);
    }
    try {
      commonsCompressCompressorStreamFactory(remoteFile.getInputStream());
    } catch (CompressorException e) {
      throw new RuntimeException(e);
    }

    PrintWriter out = response.getWriter();
    out.println("<html><body>end</body></html>");
  }

  public void destroy() {}
}
