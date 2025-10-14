package labSyncer.services;

import labSyncer.utils.UploadUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;

public class FileSharer {

    private HashMap<Integer, String> availableFiles;

    public FileSharer() {
        availableFiles = new HashMap<>();
    }

    // TODO : Add timeout
    public int offerFile(String filePath) {
        int port;
        while(true){
            port = UploadUtils.generatePort();
            if(!availableFiles.containsKey(port)){
                availableFiles.put(port,filePath);
                return port;
            }
        }
    }

    public void startFileServer(int port){
        String filePath = availableFiles.get(port);
        if(filePath == null){
            System.out.println("No file is associated with port: " + port);
            return;
        }

        try (ServerSocket serverSocket = new ServerSocket(port)) {
            System.out.println("Serving file " + new File(filePath).getName() + " on port " + port);
            Socket clientSocket = serverSocket.accept();
            System.out.println("Client connection " + clientSocket.getInetAddress());
            new Thread(new FileSenderHandler(clientSocket, filePath)).start();
        } catch (Exception e) {
            System.err.println("Error handler on port number " + port);
        }
    }

    private static class FileSenderHandler implements Runnable{

        private final Socket clientSocket;
        private final String filePath;

        public FileSenderHandler(Socket clientSocket, String filePath) {
            this.clientSocket = clientSocket;
            this.filePath = filePath;
        }

        @Override
        public void run() {
            try (FileInputStream fis = new FileInputStream(filePath)) {
                OutputStream os = clientSocket.getOutputStream();
                String fileName = new File(filePath).getName();
                String header = "Filename " + fileName + "\n";
                os.write(header.getBytes());

                byte[] buffer = new byte[4096];
                int byteRead;
                while((byteRead = fis.read(buffer)) != -1){
                    os.write(buffer, 0, byteRead);
                }
                System.out.println("File "+ fileName + "sent to " + clientSocket.getInetAddress() );
            }
            catch(Exception e){
                System.err.println("Error while sending file to client " + e.getMessage());
            } finally{
                try {
                    clientSocket.close();
                } catch (Exception e) {
                    System.out.println("Error closing client socket " + e.getMessage());
                }
            }
        }
    }

}
