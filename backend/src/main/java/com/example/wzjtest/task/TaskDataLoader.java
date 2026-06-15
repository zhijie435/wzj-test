package com.example.wzjtest.task;

import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class TaskDataLoader implements CommandLineRunner {
    private final TaskRepository taskRepository;

    public TaskDataLoader(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @Override
    public void run(String... args) {
        if (taskRepository.count() > 0) {
            return;
        }
        taskRepository.saveAll(List.of(
                new Task("Create a Vue frontend"),
                new Task("Expose Java REST APIs"),
                new Task("Store sample data in H2 memory")
        ));
    }
}
